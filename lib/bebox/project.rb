
module Bebox
  class Project

    include Bebox::Logger
    include Bebox::FilesHelper

    attr_accessor :name, :vagrant_box_base, :parent_path, :vagrant_box_provider, :environments, :path, :created_at

    def initialize(name, vagrant_box_base, parent_path, vagrant_box_provider, default_environments = [])
      self.name = name
      self.vagrant_box_base = vagrant_box_base
      self.parent_path = parent_path
      self.vagrant_box_provider = vagrant_box_provider
      self.environments = []
      self.path = "#{self.parent_path}/#{self.name}"
      default_environments.each do |env|
        self.environments << Bebox::Environment.new(env, self.path)
      end
    end

		# Project creation phase
    def create
    	create_project_directory
      create_puppet_base
      create_project_config
      create_checkpoints
      bundle_project
    end

    # Obtain the project name without 'bebox-' prefix
    def shortname
      self.name.gsub('bebox-', '')
    end

    # Create project directory
    def create_project_directory
      FileUtils.mkdir_p "#{self.parent_path}/#{self.name}"
    end

    # Generate project config files
    def create_project_config
      # Create deploy directories
      create_config_deploy_directories
      # Generate dot files
      generate_dot_bebox_file
      generate_gitignore_file
      # Generate ruby version file
      generate_ruby_version
      # Generate Capfile and deploy files
      create_capfile
      generate_deploy_files
      # Generate Gemfile
      create_gemfile
      # Create the default environments
      create_default_environments
    end

    # Get Project vagrant box provider from the .bebox file
    def self.vagrant_box_provider_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['vagrant_box_provider']
    end

    # Get Project vagrant box base from the .bebox file
    def self.vagrant_box_base_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['vagrant_box_base']
    end

    # Get short project name from the .bebox file
    def self.shortname_from_file(project_root)
      project_name = self.name_from_file(project_root)
      project_name.gsub("bebox-", "")
    end

    # Get Project name from the .bebox file
    def self.name_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['project']
    end

    # Create rbenv local
    def generate_ruby_version
      ruby_version = (RUBY_PATCHLEVEL == 0) ? RUBY_VERSION : "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      File.open("#{self.path}/.ruby-version", 'w') do |f|
        f.write ruby_version
      end
    end

    # Generate .bebox file
    def generate_dot_bebox_file
      # Set the creation time for the project
      self.created_at = DateTime.now.to_s
      # Create the .bebox file from template
      generate_file_from_template("#{Bebox::FilesHelper.templates_path}/project/dot_bebox.erb", "#{self.path}/.bebox", {project: self})
    end

    # Generate .gitignore file
    def generate_gitignore_file
      generate_file_from_template("#{Bebox::FilesHelper.templates_path}/project/gitignore.erb", "#{self.path}/.gitignore", {steps: Bebox::PROVISION_STEP_NAMES})
    end

    # Create templates directories
    def create_templates_directories
      FileUtils.cd(self.path) { FileUtils.mkdir_p %w{templates/roles templates/profiles} }
    end

    # Create the default base roles and profiles in the project
    def copy_default_roles_profiles
      # Copy default roles and profiles to project templates directory
      FileUtils.cp_r "#{Bebox::FilesHelper.templates_path}/puppet/default_roles/.", "#{self.path}/templates/roles"
      FileUtils.cp_r "#{Bebox::FilesHelper.templates_path}/puppet/default_profiles/.", "#{self.path}/templates/profiles"
      # Copy default roles and profiles to project roles and profiles available
      FileUtils.cp_r "#{Bebox::FilesHelper.templates_path}/puppet/default_roles/.", "#{self.path}/puppet/roles"
      FileUtils.cp_r "#{Bebox::FilesHelper.templates_path}/puppet/default_profiles/.", "#{self.path}/puppet/profiles"
    end

    # Create config deploy and keys directories
    def create_config_deploy_directories
      FileUtils.cd(self.path) { FileUtils.mkdir_p 'config/environments' }
    end

    # Create the default environments
    def create_default_environments
      self.environments.map{|environment| environment.create}
    end

    # Create Capfile for the project
    def create_capfile
      write_content_to_file("#{path}/Capfile", File.read("#{Bebox::FilesHelper.templates_path}/project/Capfile.erb"))
    end

    # Create Gemfile for the project
    def create_gemfile
      write_content_to_file("#{self.path}/Gemfile", File.read("#{Bebox::FilesHelper.templates_path}/project/Gemfile.erb"))
    end

    # Create puppet base directories and files
    def create_puppet_base
      # Create templates directories
      create_templates_directories
      # Generate SO dependencies files
      generate_so_dependencies_files
      # Copy puppet install files
      copy_puppet_install_files
      # Generate steps directories
      generate_steps_directories
      # Generate steps templates
      generate_steps_templates
      # Copy the default_roles and default_profiles to project
      copy_default_roles_profiles
    end

    # Generate steps directories
    def generate_steps_directories
      Bebox::PROVISION_STEP_NAMES.each do |step|
        FileUtils.cd(self.path) { FileUtils.mkdir_p "puppet/steps/#{step}" }
        FileUtils.cd("#{self.path}/puppet/steps/#{step}") { FileUtils.mkdir_p %w{ hiera/data manifests modules } }
      end
      FileUtils.cd(self.path) { FileUtils.mkdir_p %w{ puppet/roles puppet/profiles } }
    end

    # Generate steps templates for hiera and manifests files
    def generate_steps_templates
      Bebox::PROVISION_STEPS.each do |step|
        ssh_key = ''
        step_dir = Bebox::Provision.step_name(step)
        templates_path = Bebox::FilesHelper::templates_path
        # Generate site.pp template
        generate_file_from_template("#{templates_path}/puppet/#{step}/manifests/site.pp.erb", "#{self.path}/puppet/steps/#{step_dir}/manifests/site.pp", {nodes: []})
        # Generate hiera.yaml template
        generate_file_from_template("#{templates_path}/puppet/#{step}/hiera/hiera.yaml.erb", "#{self.path}/puppet/steps/#{step_dir}/hiera/hiera.yaml", {step_dir: step_dir})
        # Generate common.yaml template
        generate_file_from_template("#{templates_path}/puppet/#{step}/hiera/data/common.yaml.erb", "#{self.path}/puppet/steps/#{step_dir}/hiera/data/common.yaml", {step_dir: step_dir, ssh_key: ssh_key, project_name: self.shortname})
      end
    end

    # Copy puppet install files
    def copy_puppet_install_files
      FileUtils.cd(self.path) { FileUtils.mkdir_p 'puppet/lib/deb' }
      FileUtils.cp_r "#{lib_path}/deb/.", "#{self.path}/puppet/lib/deb"
    end

    # Generate SO dependencies files
    def generate_so_dependencies_files
      FileUtils.cd(self.path) { FileUtils.mkdir_p 'puppet/prepare/dependencies/ubuntu' }
      ubuntu_dependencies_content = File.read("#{Bebox::FilesHelper.templates_path}/project/ubuntu_dependencies")
      File::open("#{self.path}/puppet/prepare/dependencies/ubuntu/packages", "w")do |f|
        f.write(ubuntu_dependencies_content)
      end
    end

    def self.so_dependencies
      File.read("#{Bebox::FilesHelper.templates_path}/project/ubuntu_dependencies").gsub(/\s+/, ' ')
    end

    # Create checkpoints base directories
    def create_checkpoints
      FileUtils.cd(self.path) { FileUtils.mkdir_p '.checkpoints/environments' }
    end

    # Bundle install packages for project
    def bundle_project
      info _('model.project.bundle')
      `cd #{self.path} && BUNDLE_GEMFILE=Gemfile bundle install`
    end

    # Generate the deploy file for the project
    def generate_deploy_files
      generate_file_from_template("#{Bebox::FilesHelper.templates_path}/project/config/deploy.erb", "#{self.path}/config/deploy.rb", {project: self})
    end

    # Path to the lib directory in the gem
    def lib_path
      Pathname(__FILE__).dirname.parent
    end

    # Obtain the ssh public key from file in environment
    def self.public_ssh_key_from_file(project_root, environment)
      ssh_key_path = "#{project_root}/config/environments/#{environment}/keys/id_rsa.pub"
      return (File.exist?(ssh_key_path)) ? File.read(ssh_key_path).strip : ''
    end

    # Delete all files referent to a project
    def destroy
      FileUtils.cd(self.parent_path) { FileUtils.rm_rf self.name }
    end
  end
end