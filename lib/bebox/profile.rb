require 'tilt'

module Bebox
  class Profile

    attr_accessor :project_root, :name, :path

    def initialize(name, project_root, path)
      self.project_root = project_root
      self.name = name
      self.path = path
    end

    # Create all files and directories related to a profile
    def create
      create_profile_directory
      generate_manifests_file
      generate_puppetfile
    end

    # Delete all files and directories related to a profile
    def remove
      `cd #{self.project_root} && rm -r puppet/profiles/#{self.name}`
    end

    # Lists existing profiles
    def self.list(project_root)
      Dir.chdir("#{project_root}/puppet/profiles") { Dir.glob("**/manifests").map{ |f| File.dirname(f) } }
      # Dir["#{project_root}/puppet/profiles/*"].map { |f| File.basename(f) }
    end

    # Create the directories for the profile
    def create_profile_directory
      `cd #{self.project_root} && mkdir -p puppet/profiles/#{relative_path}/manifests`
    end

    # Generate the manifests init.pp file
    def generate_manifests_file
      manifests_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/profiles/manifests/init.pp.erb")
      File.open("#{absolute_path}/manifests/init.pp", 'w') do |f|
        f.write manifests_template.render(nil, :profile => self)
      end
    end

    # Generate the Puppetfile
    def generate_puppetfile
      puppetfile_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/profiles/Puppetfile.erb")
      File.open("#{absolute_path}/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(nil)
      end
    end

    # Path to the templates directory in the gem
    def templates_path
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Path to the profile directory in the project
    def absolute_path
      "#{self.project_root}/puppet/profiles/#{relative_path}"
    end

    # Counts existing profiles
    def self.profiles_count(project_root)
      Bebox::Profile.list(project_root).count
    end

    # Check if the profile has a valid name
    def self.valid_name?(name)
      valid_name = (name =~ /\A[a-z][a-z0-9_]*\Z/).nil? ? false : true
      valid_name && !Bebox::RESERVED_WORDS.include?(name)
    end

    # Check if the profile has a valid path name
    def self.valid_pathname?(pathname)
      #Split the name and validate each path part
      pathname.split('/').each do |path_child|
        valid_name = (path_child =~ /\A[a-z][a-z0-9_]*\Z/).nil? ? false : true
        valid_name && !Bebox::RESERVED_WORDS.include?(path_child)
        return false unless valid_name
      end
      # Return true if all parts are valid
      true
    end

    # Clean a path to make it valid
    def self.cleanpath(path_name)
      valid_path = Pathname.new(path_name).cleanpath.to_path.split('/').reject{|c| c.empty? }
      return valid_path.nil? ? '' : valid_path.join('/')
    end

    # Create the profile path relative to the project
    def relative_path
      File.join("#{self.path}", "#{self.name}")
    end

    # Generate the namespace name from the profile relative path
    def namespace_name
      relative_path.gsub('/','::')
    end
  end
end