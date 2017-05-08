# frozen_string_literal: true

module VagrantBindfs
  module Vagrant
    class Plugin < ::Vagrant.plugin('2')
      name 'bindfs'
      description <<-DESC
      A Vagrant plugin to automate bindfs mount in the VM. This allow you to change owner, group and permissions on files and, for example, work around NFS share permissions issues.
      DESC

      config(:bindfs) do
        Config
      end

      include Capabilities

      %w[up reload].each do |action|
        action_hook(:bindfs, "machine_action_#{action}".to_sym) do |hook|
          hooks.each do |(name, middleware)|
            hook.before(middleware, Actions::Mounter, name)
          end
          hook.before(hooks[hooks.keys.first], Actions::Installer)
        end
      end

      class << self
        def hooks
          @hooks ||= begin
            synced_folders = if ::Vagrant::Action::Builtin.const_defined? :NFS
                               ::Vagrant::Action::Builtin::NFS
                             else
                               ::Vagrant::Action::Builtin::SyncedFolders
                             end

            {
              synced_folders: synced_folders,
              provision:      ::Vagrant::Action::Builtin::Provision
            }
          end
        end
      end
    end
  end
end
