#!/usr/bin/env ruby
ascii_art="
 ;;;;;;iiiii;;                          
                 i!!!!!!!!!!!!!!!~{:!!!!i
             i!~!!))!!!!!!!!!!!!!!!!!!!!!!!!
          i!!!{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!i
       i!!)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    '!h!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  '!!`!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!i
   /!!!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
' ':)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ~:!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
..!!!!!\!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 `!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 ~ ~!!!)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~
~~'~{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:'~ 
{-{)!!{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:!
`!!!!{!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!':!!!
' {!!!{>)`!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!)!~..
:!{!!!{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! -!!:
    ~:!4~/!!!!!!!!!!!!!!!!!!!~!!!!!!!!!!!!!!!!!!!!!!!!!!
     :~!!~)(!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      ``~!!).~!!!!!!!!!!!!!{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!:
            ~  '!\!!!!!!!!!!(!!!!!!!!!!!!!!!!!!!!!!4!!!~:
           '      '--`!!!!!!!!/:\!!{!!((!~.~!!`?~-      :
              ``-.    `~!{!`)(>~/ \~                   :
   .                \  : `{{`. {-   .-~`              /
    .          !:       .\\?.{\   :`      .          :!
    \ :         `      -~!{:!!!\ ~     :!`         .>!
    '  ~          '    '{!!!{!!!t                 ! !!
     '!  !.            {!!!!!!!!!              .~ {~!
      ~!!..`~:.       {!!!!!!!!!!:          .{~ :LS{
       `!!!!!!h:!?!!!!!!!!!!!!!(!!!!::..-~~` {!!!!.
         4!!!!!!!!!!!!!!!!!!!!!~!{!~!!!!!!!!!!!!'
          `!!!!!!!!!!!!!!!!!!!!(~!!!!!!!!!!!!!~
            `!!!!!!!!!!!{\``!!``(!!!!!!!!!~~  .
             `!!!!!!!!!!!!!!!!!!!!!!!!(!:
               .!!!!!!!!!!!!!!!!!!!!!\~ 
               .`!!!!!!!/`.;;~;;`~!! '
                 -~!!!!!!!!!!!!!(!!/ .
                    `!!!!!!!!!!!!!!'
                      `\!!!!!!!!!~

                       YOU ARE IN !!!!! 
"
require 'socket'
require 'thread'
require 'fcntl'

class Socket_loop
  @@list_of_sockets = []
  def self.create_server
    @acceptor = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @acceptor.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
    @address = Socket.pack_sockaddr_in(4242, '0.0.0.0')
    @acceptor.bind(@address)
    @acceptor.listen(1000)
    puts "--after the socket is bound and my pid is #{$$}"        
  end
  
  def self.selected
    puts "--en el select and pid #{$$}"
    @result = select( [@acceptor], nil ,nil)
    @result
  end
  
  def self.push_connection(newsock)
    @@list_of_sockets << newsock
  end
  
  def self.accept2   
   @acceptor  
            
  end
  
end

class Executor  
  def self.fork_block(fork_amount, block)
    @rd, @wr = IO.pipe
    pids = Array.new
    puts "I am your father..."
   
     
    pids[0]=$$
   fork_amount.each do |i|
      
      pids[i] = fork

      if  $$ == pids[0] 
        # Only for the father
        if i == fork_amount.last
          puts "--Im going to return"
          return  pids, @rd
        end 
      else
#============JAIL=========        
          pid=$$
           
           puts "Im the son Sending pid #{pid} #{Time.now}  message to parent"
           index= 0
           @locked = 0
           @todas_las_conexiones = []
           while true do
         
             puts "son's pid #{$$} and so call select\n\n"
             if @locked == 1 
               puts "======================SOME THREAD have locked the connection WAIT!! #{$$} #{Time.now}=============== "      
             end 
              
            if ! Socket_loop::selected.nil? && @locked != 1                 
              index += 1
              @newsock = Socket_loop::accept2.accept
              @locked = 1
                
              Thread.abort_on_exception = true
              Thread.new(@newsock) do
                
                begin   
                 thread_socket = @newsock[0]
                 @locked = 0 
                 if ! thread_socket.nil? 
                   
                   block.call(thread_socket,index,@wr)     
                    
                 else
                   puts "\nLoser After #{$$}\n\n"
                 end
                  puts "\nKilling thread #{$$}\n\n"
                   rescue Exception => e  
                     puts " ERROR"
                     puts e.message  
                     puts e.backtrace.inspect  
                   end
                 Thread.kill(Thread.current)   
              end
              puts "CLOSE ANY socket REACHING this point"
             
                 
             end
          
           end
         exit
#==========JAIL=============          
      end
    end  
  end
end

new_proc = Proc.new do |thread_socket,index,wr|
  require 'pty'   

   m, s = PTY.open
   #s.raw! # disable newline conversion.
wr.puts("Im child with pid= #{$$}")
   m_pid = $$
   pid = fork 
   if $$ !=  m_pid
      p s.path

      $stdin.reopen s
      $stderr.reopen s
      $stdout.reopen s
      Process.setsid
       puts "slave #{Time.now}"
       exec("/bin/bash -l -i ")
       s.puts "TEST"
       sleep 3
   else
      thread_socket.puts ascii_art
   while true
      cbuf = ""
      command = ""
      escape = ""
      command=""
      # We shall not block
      begin
        m.write thread_socket.recv_nonblock(8) 
      rescue
       puts "NOTHING TO READ FROM USER DOES THE SERVER HAS SOMETHING?"
       sleep 0.01
      end
      
      result =""

      dormir=0.001
      inc=0.001
      counter = 0
      while true
        begin
         
          puts "New Read = #{result}"

          sleep dormir

          thread_socket.write m.read_nonblock(1024)

        rescue 
          puts "END_OF_THE_STREAM"
            counter = counter + 1 
            if counter < 10
              dormir + inc
              retry
            else
              dormir = 0.01
              break
            end
        end
      end
      result=""
  end
  
end       
   
end

Socket_loop::create_server
pids, rd  = Executor::fork_block (1..10), new_proc



puts "Ok Im the father #{$$} we can continue from here"
while true do 
    puts "===inside the parent pid #{$$} #{Time.now} "
    while ! Socket_loop::selected.nil?
     if  select( [rd], nil ,nil,6)
       puts "Content in parent #{$$} on the end of the socket #{rd.gets}" 
     else
      puts "UPSSS.. no one can handle that connection!"
      sleep 50
      a = Socket_loop::accept2.accept
      a[0].write("Shitt!!!!")
      exit
     end  
    end
    
    sleep (20)           
end


puts "exit"

