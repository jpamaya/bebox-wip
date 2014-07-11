module Bebox
  module GeneralCommands

    def load_general_commands
      # Project creation phase command
      desc 'Create a new bebox project through a simple wizard'
      arg_name '[project_name]'
      command :new do |project_command|
        project_command.action do |global_options,options,args|
          if args.count > 0
            Bebox::ProjectWizard.new.create_new_project(args.first)
          else
            help_now!(error('You did not supply a project name'))
          end
        end
      end
    end
  end
end