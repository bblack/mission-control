require 'spec_helper'

describe MissionControl::Models::Control do
  before do
    allow(STDOUT).to receive(:puts)
  end

  let(:payload) do
    {
      'action' => 'synchronize',
      'pull_request' => {
        'head' => { 'sha' => 'abc123', 'ref' => 'branch' },
        'number' => '23',
        'base' => { 'ref' => 'base_branch' }
      },
      'repository' => {
        'full_name' => 'calendly/mission-control'
      }
    }
  end

  let(:pull_request) do
    MissionControl::Models::PullRequest.new(
      event_type: 'pull_request',
      payload: payload
    )
  end

  let(:name) { 'Code Review' }
  let(:users) { ['aterris'] }
  let(:paths) { '*' }
  let(:count) { 1 }

  let(:control) do
    MissionControl::Models::Control.new(
      pull_request: pull_request,
      name: name,
      users: users,
      paths: paths,
      count: count
    )
  end

  describe '::fetch' do
    let(:github_stub) { double('github') }
    before do
      allow(MissionControl::Services::GithubService).to receive(:client).and_return(github_stub)

      config_file = File.read('spec/fixtures/.mission-control.yml')
      allow(github_stub).to receive(:content).and_return(:content => Base64.encode64(config_file))
    end

    it 'skip if no config file found in the repo' do
      allow(github_stub).to receive(:content).and_return(nil)
      expect(MissionControl::Models::Control).to_not receive(:new)
    end

    it 'fetches controls from repo' do
      expect(github_stub).to receive(:content).with(
        'calendly/mission-control',
        :path => '.mission-control.yml',
        :ref => 'base_branch'
      )

      controls = MissionControl::Models::Control.fetch(pull_request: pull_request)

      expect(controls.length).to eq(3)
    end

    it 'maps data to controls correctly' do
      controls = MissionControl::Models::Control.fetch(pull_request: pull_request)

      expect(controls.first.name).to eq('Code Review')
      expect(controls.first.users).to eq(%w[cboyle jperalta])
      expect(controls.first.paths).to eq('*')
      expect(controls.first.count).to eq(2)
    end
  end

  describe '::execute!' do
    let(:code_review_control) { double('control') }
    let(:qa_review_control) { double('control') }

    before do
      allow(MissionControl::Models::Control).to receive(:fetch).and_return([code_review_control, qa_review_control])
    end

    it 'executes all controls' do
      expect(code_review_control).to receive(:execute!)
      expect(qa_review_control).to receive(:execute!)

      MissionControl::Models::Control.execute!(pull_request: pull_request)
    end
  end

  describe '#active?' do
    context 'all paths' do
      let(:paths) { '*' }

      it 'active' do
        allow(pull_request).to receive(:files).and_return(['/lib/mission_control.rb'])
        expect(control.active?).to be true
      end
    end

    context 'ignored files' do
      let(:paths) { ['*', '!README.md'] }

      it 'active' do
        allow(pull_request).to receive(:files).and_return(['/lib/mission_control.rb'])
        expect(control.active?).to be true
      end

      it 'inactive' do
        allow(pull_request).to receive(:files).and_return(['/README.md'])
        expect(control.active?).to be false
      end
    end

    context 'ignored directory' do
      let(:paths) { ['*', '!specs/'] }

      it 'active' do
        allow(pull_request).to receive(:files).and_return(['/lib/mission_control.rb'])
        expect(control.active?).to be true
      end

      it 'inactive' do
        allow(pull_request).to receive(:files).and_return(['/specs/mission_control_spec.rb'])
        expect(control.active?).to be false
      end
    end
  end

  describe '#execute!' do
    context 'inactive control' do
      before do
        allow(control).to receive(:active?).and_return(false)
      end

      it 'set control approved in github' do
        expect(pull_request).to receive(:status).with(state: 'success', name: name, description: 'Not Required')
        control.execute!
      end
    end

    context 'active control' do
      before do
        allow(control).to receive(:active?).and_return(true)
      end

      context 'approved' do
        it 'set control approved in github' do
          allow(pull_request).to receive(:approvals).and_return(['aterris'])

          expect(pull_request).to receive(:status).with(
            state: 'success',
            name: name,
            description: 'Required: 1 | Approved by: aterris'
          )

          control.execute!
        end
      end

      context 'not approved' do
        it 'set control pending in github' do
          allow(pull_request).to receive(:approvals).and_return(['jperalta'])

          expect(pull_request).to receive(:status).with(
            state: 'pending',
            name: name,
            description: 'Required: 1'
          )

          control.execute!
        end
      end

      context 'not enough approvals' do
        let(:count) { 2 }

        it 'set control pending in github' do
          allow(pull_request).to receive(:approvals).and_return(['aterris'])

          expect(pull_request).to receive(:status).with(
            state: 'pending',
            name: name,
            description: 'Required: 2 | Approved by: aterris'
          )

          control.execute!
        end
      end
    end
  end
end
