defmodule MainServer do
    use GenServer

    def start_link() do
        users = %{}
        hashtags = %{}
        mentions = %{}
        state_map = %{"users" => users, "hashtags" => hashtags, "mentions" => mentions}
        {:ok,initial_state} = GenServer.start_link(MainServer, [users,hashtags,mentions], name: :"#{"mainserver"}")   
    end

    def init(initial_state) do
        {:ok,initial_state}
    end

    def get_user_state(username) do
        current_state = get_state("mainserver")
        user_state = Map.fetch(current_state,"users")
        my_user = Map.fetch(user_state,:"#{username}")
        my_user
    end

    def check_user(username) do
        current_state = get_user_state(username)
        if current_state == nil do
            false
        else
            true
        end
    end

    def get_state(:mainserver) do
        pid = GenServer.whereis("mainserver")
        GenServer.call(pid, {:mainserver})
    end

    def handle_call(:mainserver,_from,my_state) do
        {:reply,my_state,my_state}
    end

    def create_user(username) do
        pid = GenServer.whereis("mainserver")
        GenServer.call(pid,{:add_new_user,username})
    end
    
    def handle_call({:add_new_user,username}, my_state) do
        user_state = User.get_state(username)
        username = Map.fetch(user_state,"username")
        user_map = Map.fetch(my_state, "users")
        new_state = Map.put(user_map,"users",user_state)
        {:reply,new_state,new_state}
    end

    def add_follower(username,my_name) do
        pid = GenServer.whereis(:"#{"mainserver"}")
        GenServer.cast(pid, {:add_follower,username,my_name})
    end

    def handle_cast({:add_follower,username,my_name},my_state) do
        user_map = Map.fetch(username,"username")
        my_user = Map.fetch(user_map,:"#{username}")
        followers_list = Map.fetch(my_user,"followers") ++ my_name
        new_state = Map.put(my_user, "followers", followers_list)

        {:noreply,new_state}
    end

    def handle_call(pid, {:go_offline,user_state, username},my_state) do
        my_state = Map.put(my_state,"users",user_state)
        {:reply,my_state} 
    end

end