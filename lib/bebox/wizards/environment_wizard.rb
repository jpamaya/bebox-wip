require_relative '../environment'
require 'highline/import'
require 'bebox/logger'

module Bebox
  class EnvironmentWizard
    include Bebox::Logger
    # Create a new environment
    def create_new_environment(project_root, environment_name)
      # Check if the environment exist
      return error("The environment #{environment_name} already exist!.") if Bebox::Environment.environment_exists?(project_root, environment_name)
      # Environment creation
      environment = Bebox::Environment.new(environment_name, project_root)
      environment.create
      ok 'Environment created!.'
    end

    # Removes an existing environment
    def remove_environment(project_root, environment_name)
      # Check if the environment exist
      return error("The environment #{environment_name} don't exist!.") unless Bebox::Environment.environment_exists?(project_root, environment_name)
      # Confirm deletion
      return warn('Nothing done!.') unless confirm_environment_deletion?
      # Environment deletion
      environment = Bebox::Environment.new(environment_name, project_root)
      environment.remove
      ok 'Environment removed!.'
    end

    # Ask for confirmation of environment deletion
    def confirm_environment_deletion?
      quest 'Are you sure that you want to delete the environment?'
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an existent environment
    def choose_environment(environments)
      choose do |menu|
        menu.header = title('Choose an existent environment:')
        environments.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end
  end
end