def usage
  puts <<~USAGE
    usage: #{$PROGRAM_NAME} variable {environment}

    environment defaults to 'sandbox' if not given
  USAGE
end

environment = ARGV[1] || "sandbox"
variable = ARGV[0]

unless variable
  usage
  exit 1
end

require 'json'

FILE = 'namecheap-config.json'

config = JSON.parse(File.read(FILE))

env = config[environment]

if env && env.has_key?(variable)
  puts env[variable]
else
  STDERR.puts "#{variable} not found in #{environment} config"
  exit 1
end