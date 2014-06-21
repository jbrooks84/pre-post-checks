require 'net/telnet'
require 'optparse'

options = {:username => nil, :password => nil}

OptionParser.new do |opts|
  opts.banner = "Usage: pre_post_diff_v1.rb [options] devicefile"
  opts.on('-u', '--username USERNAME', String, 'Your Username For Pre/Post Checks') { |v| options[:username] = v }
  opts.on('-p', '--password PASSWORD', String, 'Your Password For Pre/Post Checks') { |v| options[:password] = v }
  opts.on('-z', '--enable-password ENABLE-PASSWORD', String, 'Your Enable Password For Pre/Post Checks') { |v| options[:enablepassword] = v }
  opts.on('-d', '--devices DEVICES', 'File with list of devices') { |v| options[:devices] = v }
  opts.on('-c', '--commands COMMANDS', 'File with list of commands') { |v| options[:commands] = v }
  opts.on('-s', '--preorpostdiff PREORPOSTDIFF', 'PRE, POST or DIFF') { |v| options[:preorpostdiff] = v }
  opts.on('-e', '--enable ENABLE', 'Eable yes or no') { |v| options[:enable] = v }
end.parse!

if options[:username] == nil
  print 'Enter Userame: '
    options[:username] = gets.chomp
end

if options[:password] == nil
  print 'Enter Password: '
    options[:password] = gets.chomp
end

if options[:enablepassword] == nil
  print 'Enter Enable Password: '
    options[:enablepassword] = gets.chomp
end

if options[:devices] == nil
  print 'Enter device file: '
    options[:devices] = gets.chomp
end

if options[:commands] == nil
  print 'Enter command file: '
    options[:commands] = gets.chomp
end

if options[:preorpostdiff] == nil
        print 'Enter PRE, POST or DIFF: '
    options[:preorpostdiff] = gets.chomp
end

if options[:enable] == nil
        print 'Enter Enable YES or NO: '
    options[:enable] = gets.chomp
end

@node_hostnames = []
File.readlines(options[:devices]).map do |line|
  @node_hostnames << line.chomp
end

@node_commands = []
File.readlines(options[:commands]).map do |line|
  @node_commands << line.chomp
end

@user = options[:username]
@pass = options[:password]
@enablepass = options[:enablepassword]
@enable = options[:enable]

def pre_captures()
  @node_hostnames.each do |hostname|
    puts "Device -> #{hostname}"
    logfile = open("PRE_#{hostname}.txt", "w")
    telnet = Net::Telnet::new("Host" => "#{hostname}", "Timeout" => 20, "Prompt" => /login:|Username:|Password:|[?]\z|[#] \z|[#]\z/n)
    telnet.cmd('String'=>"#{@user}")
    telnet.cmd('String'=>"#{@pass}")
    telnet.cmd('String'=>'term len 0')
    @node_commands.each do |commands|
      puts "Command -> #{commands}"
      telnet.cmd('String'=> "#{commands}") { |a| logfile.write(a) }
    end
  logfile.close
  telnet.close
  end
end

def enable_pre_captures()
  @node_hostnames.each do |hostname|
    puts "Device -> #{hostname}"
    logfile = open("PRE_#{hostname}.txt", "w")
    telnet = Net::Telnet::new("Host" => "#{hostname}", "Timeout" => 20, "Prompt" => /login:|Username:|Password:|[>]\z|[?]\z|[#] \z|[#]\z/n)
    telnet.cmd('String'=>"#{@user}")
    telnet.cmd('String'=>"#{@pass}")
    telnet.cmd('String'=>'enable')
    telnet.cmd('String'=>"#{@enablepass}")
    telnet.cmd('String'=>'term len 0')
    @node_commands.each do |commands|
      puts "Command -> #{commands}"
      telnet.cmd('String'=> "#{commands}") { |a| logfile.write(a) }
    end
  logfile.close
  telnet.close
  end
end

def post_captures()
  @node_hostnames.each do |hostname|
    puts "Device -> #{hostname}"
    logfile = open("POST_#{hostname}.txt", "w")
    telnet = Net::Telnet::new("Host" => "#{hostname}", "Timeout" => 20, "Prompt" => /login:|Username:|Password:|[#] \z|[#]\z/n)
    telnet.cmd('String'=>"#{@user}")
    telnet.cmd('String'=>"#{@pass}")
    telnet.cmd('String'=>'term len 0')
    @node_commands.each do |commands|
      puts "Command -> #{commands}"
      telnet.cmd('String'=> "#{commands}") { |a| logfile.write(a) }
    end
  logfile.close
  telnet.close
  end
end

def enable_post_captures()
  @node_hostnames.each do |hostname|
    puts "Device -> #{hostname}"
    logfile = open("POST_#{hostname}.txt", "w")
    telnet = Net::Telnet::new("Host" => "#{hostname}", "Timeout" => 20, "Prompt" => /login:|Username:|Password:|[>]\z|[#] \z|[#]\z/n)
    telnet.cmd('String'=>"#{@user}")
    telnet.cmd('String'=>"#{@pass}")
    telnet.cmd('String'=>'enable')
    telnet.cmd('String'=>"#{@enablepass}")
    telnet.cmd('String'=>'term len 0')
    @node_commands.each do |commands|
      puts "Command -> #{commands}"
      telnet.cmd('String'=> "#{commands}") { |a| logfile.write(a) }
    end
  logfile.close
  telnet.close
  end
end

def diff_captures()
    @node_hostnames.each do |hostname|
        logfile = open("Complete_DIFF.txt", "a")
        @Lost_Config = `diff -y --suppress-common-lines PRE_#{hostname}.txt POST_#{hostname}.txt | grep -E "*<"`
        @New_Config = `diff -y --suppress-common-lines PRE_#{hostname}.txt POST_#{hostname}.txt | grep -E "*>"`
        @Changed_Config = `diff -y --suppress-common-lines PRE_#{hostname}.txt POST_#{hostname}.txt | grep -E "*|"`
        logfile.write("-------------------------------------------------------\n")
        logfile.write("######### #{hostname} Lost Configuration\n")
        logfile.write("-------------------------------------------------------\n")
        logfile.write("#{@Lost_Config}")
        logfile.write("-------------------------------------------------------\n")
        logfile.write("######### #{hostname} New Configuration\n")
        logfile.write("-------------------------------------------------------\n")
        logfile.write("#{@New_Config}")
        logfile.write("-------------------------------------------------------\n")
        logfile.write("######### #{hostname} Changed Configuration\n")
        logfile.write("-------------------------------------------------------\n")
        logfile.write("#{@Changed_Config}")
        logfile.close
        end
end

if options[:preorpostdiff] == 'PRE' and options[:enable] == 'YES'
  enable_pre_captures()
end

if options[:preorpostdiff] == 'PRE' and options[:enable] == 'NO'
  pre_captures()
end

if options[:preorpostdiff] == 'POST' and options[:enable] == 'YES'
  enable_post_captures()
end

if options[:preorpostdiff] == 'POST' and options[:enable] == 'NO'
  post_captures()
end

if options[:preorpostdiff] == 'DIFF'
  diff_captures()
end

