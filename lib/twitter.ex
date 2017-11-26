defmodule Twitter do
  use GenServer 

  def main(args) do
    pid = start_main_server()

    #create users 
    users = [{"sri","mis"},{"abhi","mis"},{"karan","mis"},{"keyur","mis"},{"aru","mis"}]
    Enum.each users, fn user-> username = elem(user,0) 
                               password = elem(user,1) 
                               create_user(username,password) 
                     end
    
  end

  #utility test funtions
  def start_main_server() do
    pid = MainServer.start_link()
    pid
  end

  def create_user(username,password) do
    #access main server's user list to check if this user already exists
    user_exists = MainServer.check_user(username)
    if user_exists == false do
      user_pid = User.start_link(username,password)
      MainServer.create_user(user_pid)
    end
  end

  def go_online(username,password) do 
    user_state = MainServer.get_user_state(username)
    User.go_online(user_state,username,password)
  end

  def validate_username(username) do
    #(?=^.(3,20)$)
    true = Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9]*[._-]?[a-zA-Z0-9]/,"Srishti")
  end
  
  def validate_password(password) do
    true = Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9]*[._-]?[a-zA-Z0-9]/,"Srishti")
    #to do password regex
  end
end
