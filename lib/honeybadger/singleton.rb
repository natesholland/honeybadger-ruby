require 'forwardable'
require 'honeybadger/agent'

# The Singleton module includes the public API for Honeybadger which can be
# accessed via the global agent (i.e. `Honeybadger.notify`) or via instances of
# the `Honeybadger::Agent` class.
module Honeybadger
  extend Forwardable
  extend self

  def_delegators :'Honeybadger::Agent.instance', :init!, :config, :configure,
    :context, :get_context, :flush, :stop, :with_rack_env, :exception_filter,
    :exception_fingerprint, :backtrace_filter

  def notify(exception_or_opts, opts = {})
    Agent.instance.notify(exception_or_opts, opts)
  end

  def check_in(id)
    Agent.instance.check_in(id)
  end

  def load_plugins!
    Dir[File.expand_path('../plugins/*.rb', __FILE__)].each do |plugin|
      require plugin
    end
    Plugin.load!(self.config)
  end

  def install_at_exit_callback
    at_exit do
      if $! && !$!.is_a?(SystemExit) && Honeybadger.config[:'exceptions.notify_at_exit']
        Honeybadger.notify($!, component: 'at_exit', sync: true)
      end

      Honeybadger.stop if Honeybadger.config[:'send_data_at_exit']
    end
  end

  # Deprecated
  def start(config = {})
    raise NoMethodError, <<-WARNING
`Honeybadger.start` is no longer necessary and has been removed.

  Use `Honeybadger.configure` to explicitly configure the agent from Ruby moving forward:

  Honeybadger.configure do |config|
    config.api_key = 'project api key'
    config.exceptions.ignore += [CustomError]
  end
WARNING
  end
end
