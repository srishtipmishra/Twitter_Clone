defmodule Twitter do
  use GenServer 

  def main(args) do
    args |> parse_args
    #pid = start_main_server()
    #create_numbered_users(10)
    #create users 
    
  end


  def parse_args([]) do
      IO.puts "No arguments given" 
  end    


  def parse_args(args) do
      {_, [input], _} = OptionParser.parse(args)
      
      if(input=="server") do
          start_main_server()
      end

      if(input=="client") do
          User.main()  
      end

      IO.puts " Wrong input " 
  end

  def start_main_server() do
    pid = MainServer.start_link()
    IO.puts "Created Mainserevr with PID" 
    IO.inspect pid
    pid
  end

end
