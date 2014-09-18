require 'spec_helper'

describe 'Bebox::Project', :fakefs do

  subject { build(:project) }
  let(:temporary_project) { build(:project, name: 'temporary_project') }
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      subject.create
      temporary_project.create
    end
    FakeCmd.off!
  end

  after :all do
    FakeCmd.clear!
  end

  it 'creates the project directory' do
    expect(Dir.exist?(subject.path)).to be true
  end

  it 'destroys a temporary project' do
    temporary_project.destroy
    expect(Dir.exist?(temporary_project.path)).to be false
  end

  context 'Project config files creation' do
    it 'creates the support directories' do
      expected_directories = ['templates', 'roles', 'profiles', 'spec', 'factories']
      directories = []
      directories << Dir["#{subject.path}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/*/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*expected_directories)
    end

    it 'creates the spec helper' do
      expect(File.exist?("#{subject.path}/spec/spec_helper.rb")).to be (true)
      spec_content = File.read("#{subject.path}/spec/spec_helper.rb").gsub(/\s+/, ' ').strip
      spec_template = Tilt::ERBTemplate.new("#{fixtures_path}/spec_helper.test")
      expected_spec_content = spec_template.render(nil).gsub(/\s+/, ' ').strip
      expect(spec_content).to eq(expected_spec_content)
    end

    it 'creates the spec factories' do
      expect(File.exist?("#{subject.path}/spec/factories/node.rb")).to be (true)
    end

    it 'creates the .rspec file' do
      expect(File.exist?("#{subject.path}/.rspec")).to be (true)
    end

    it 'generates a .bebox file' do
      dotbebox_content = File.read("#{subject.path}/.bebox").gsub(/\s+/, ' ').strip
      ouput_template = Tilt::ERBTemplate.new("#{fixtures_path}/dot_bebox.test.erb")
      dotbebox_expected_content = ouput_template.render(nil, created_at: subject.created_at, bebox_path: Pathname(__FILE__).dirname.parent).gsub(/\s+/, ' ').strip
      expect(dotbebox_content).to eq(dotbebox_expected_content)
    end

    it 'generates a .gitignore file' do
      expected_content = File.read("#{subject.path}/.gitignore")
      output_file = File.read("#{fixtures_path}/dot_gitignore.test")
      expect(output_file).to eq(expected_content)
    end

    it 'generates a .ruby-version file' do
      ruby_version = (RUBY_PATCHLEVEL == 0) ? RUBY_VERSION : "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      version = File.read("#{subject.path}/.ruby-version").strip
      expect(version).to eq(ruby_version)
    end

    it 'creates a Capfile' do
      expected_content = File.read("#{subject.path}/Capfile")
      output_file = File.read("#{fixtures_path}/Capfile.test")
      expect(output_file).to eq(expected_content)
    end

    it 'generates the deploy files' do
      # Generate deploy.rb file
      config_deploy_content = File.read("#{subject.path}/config/deploy.rb").gsub(/\s+/, ' ').strip
      config_deploy_output_content = File.read("#{fixtures_path}/config/deploy.test").gsub(/\s+/, ' ').strip
      expect(config_deploy_content).to eq(config_deploy_output_content)
    end

    it 'creates a Gemfile' do
      content = File.read("#{subject.path}/Gemfile").gsub(/\s+/, ' ').strip
      output = File.read("#{fixtures_path}/Gemfile.test").gsub(/\s+/, ' ').strip
      expect(output).to eq(content)
    end
  end

  context 'Create puppet base' do
    it 'generates the SO dependencies files' do
      content = File.read("#{subject.path}/puppet/prepare/dependencies/ubuntu/packages")
      output = File.read("#{fixtures_path}/puppet/ubuntu_dependencies.test")
      expect(output).to eq(content)
    end

    it 'copy the puppet installation files' do
      expect(Dir.exist?("#{subject.path}/puppet/lib/deb/puppet_3.6.0")).to be (true)
      expect(Dir["#{subject.path}/puppet/lib/deb/puppet_3.6.0/*"].count).to eq(18)
    end

    it 'generates the step directories' do
      expected_directories = ['prepare', 'profiles', 'roles', 'steps',
        'step-0', 'step-1', 'step-2', 'step-3',
        'hiera', 'manifests', 'modules', 'data']
      directories = []
      directories << Dir["#{subject.path}/puppet/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/puppet/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/puppet/*/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/puppet/*/*/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*expected_directories)
    end

    it 'copy the default roles and profiles' do
      expected_roles_directories = ['fundamental', 'security', 'users']
      expected_profiles_directories = ['base', 'fundamental', 'ruby', 'manifests', 'sudo', 'users', 'security', 'fail2ban', 'iptables', 'ssh', 'sysctl']
      directories = Dir["#{subject.path}/puppet/roles/*/"].map { |f| File.basename(f) }.uniq
      expect(directories).to include(*expected_roles_directories)
      directories = Dir["#{subject.path}/puppet/profiles/**/*"].map{|f|File.basename(f)}.uniq
      expect(directories).to include(*expected_profiles_directories)
    end

    context 'generate steps templates' do
      it 'generates the manifests templates' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("#{fixtures_path}/puppet/steps/#{step}/manifests/site.pp.test")
          output = File.read("#{subject.path}/puppet/steps/#{step}/manifests/site.pp")
          expect(output).to eq(content)
        end
      end
      it 'generates the hiera config template' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("#{fixtures_path}/puppet/steps/#{step}/hiera/hiera.yaml.test")
          output = File.read("#{subject.path}/puppet/steps/#{step}/hiera/hiera.yaml")
          expect(output).to eq(content)
        end
      end
      it 'generates the hiera data common' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("#{fixtures_path}/puppet/steps/#{step}/hiera/data/common.yaml.test")
          output = File.read("#{subject.path}/puppet/steps/#{step}/hiera/data/common.yaml")
          expect(output).to eq(content)
        end
      end
    end
  end

  context 'checkpoints' do
    it 'creates checkpoints directories' do
      expected_directories = ['.checkpoints', 'environments']
      directories = []
      directories << Dir["#{subject.path}/.checkpoints/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/.checkpoints/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*expected_directories)
    end
  end

  context 'bundle project' do
    it 'install project dependencies' do
      # Fake the Gemfile.lock file creation by the bundle install command (because FakeFS)
      FileUtils.touch("#{subject.path}/Gemfile.lock")
      expect(File).to exist("#{subject.path}/Gemfile.lock")
    end
  end

  context 'create default environments' do
    it 'generates the deploy environment files' do
      subject.environments.each do |environment|
        config_deploy_vagrant_content = File.read("#{subject.path}/config/environments/#{environment.name}/deploy.rb").gsub(/\s+/, ' ').strip
        config_deploy_vagrant_output_content = File.read("#{fixtures_path}/config/deploy/#{environment.name}.test").gsub(/\s+/, ' ').strip
        expect(config_deploy_vagrant_content).to eq(config_deploy_vagrant_output_content)
      end
    end

    it 'creates environments checkpoints' do
      expected_directories = ['vagrant', 'staging', 'production', 'phases', 'phase-0', 'phase-1', 'phase-2',
        'steps', 'step-0', 'step-1', 'step-2', 'step-3']
      directories = []
      directories << Dir["#{subject.path}/.checkpoints/environments/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/.checkpoints/environments/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*expected_directories)
    end

    it 'creates environments capistrano base' do
      subject.environments.each do |environment|
        expect(Dir.exist?("#{subject.path}/config/environments/#{environment.name}")).to be (true)
      end
      expect(File.exist?("#{subject.path}/config/environments/vagrant/keys/id_rsa")).to be (true)
      expect(File.exist?("#{subject.path}/config/environments/vagrant/keys/id_rsa.pub")).to be (true)
    end
  end

  context 'self methods' do
    it 'obtains a vagrant box provider' do
      vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(subject.path)
      expect(vagrant_box_provider).to eq(subject.vagrant_box_provider)
    end

    it 'obtains a vagrant box base' do
      vagrant_box_base = Bebox::Project.vagrant_box_base_from_file(subject.path)
      expect(vagrant_box_base).to eq(subject.vagrant_box_base)
    end

    it 'obtains the SO dependencies' do
      expected_dependencies = File.read("#{subject.path}/puppet/prepare/dependencies/ubuntu/packages").gsub(/\s+/, ' ').strip
      dependencies = Bebox::Project.so_dependencies.gsub(/\s+/, ' ').strip
      expect(dependencies).to eq(expected_dependencies)
    end
  end
end