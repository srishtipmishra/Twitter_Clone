defmodule MainServer do
    use GenServer

    def start_link() do
        IO.puts "in server"
        server = "server@" <> get_ip_addr()
        Node.start(String.to_atom(server))
        Node.set_cookie :"srishti"
        mainserver = "mainserver"
        GenServer.start_link(MainServer, {},name: String.to_atom("mainserver"))   
        IO.puts "server created"
        IO.gets ""
    end

    def init(state_map) do
        users = %{}
        hashtags = %{}
        mentions = %{}
        state_map = %{"users" => users, "hashtags" => hashtags, "mentions" => mentions}
        {:ok,state_map}
    end

    def get_ip_addr do 
        {:ok,lst} = :inet.getif()
        z = elem(List.last(lst),0) 
        if elem(z,0)==127 do
        x = elem(List.first(lst),0)
        addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
        else
        x = elem(List.last(lst),0)
        addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
        end
        addr  
    end

    def handle_call({:get_user_state,args}, _from, my_state) do
        IO.puts "in get user state mainserver"
        username = elem(args,0)
        IO.inspect my_state
        user_state = Map.get(my_state,"users")
        my_user = Map.get(user_state,username)
        IO.puts "inspecting user in check user"
        {:reply,my_user, my_state}
    end

    def handle_call({:check_user, args},_from, my_state) do
        username = elem(args,0)
        #current_state = get_user_state(username)
        users = Map.get(my_state, "users")
        current_state = Map.get(users, username)
        IO.inspect current_state
        if current_state == nil do
            IO.puts "This is a new user!"
            user_exists = false
        else
            IO.puts "User already exists"
            user_exists = true
        end
        {:reply, user_exists, my_state}
    end

    def get_state() do
        user_state = GenServer.call(String.to_atom("mainserver"),{:mainserver})
    end

    def handle_call({:mainserver},_from, my_state) do
        #IO.puts "in main server state"
        {:reply, my_state, my_state}
    end
    
    def handle_call({:add_new_user,args},_from, my_state) do
        IO.puts "in mainserver add new user"
        username = elem(args,0)
        password = elem(args,1)

        user_state =  %{"username" => username, "password" => password, "tweets" => [], "followers" => [], "following" => [], "dashboard" => []}

        IO.inspect user_state

        username = Map.get(user_state,"username")
        user_map = Map.get(my_state, "users")
        user_map = Map.put(user_map,username, user_state)
        #IO.puts "check user map"
        IO.inspect user_map
        my_state = Map.put(my_state,"users",user_map)

        IO.puts "checking main server state after user insertion"
        IO.inspect my_state
        {:reply,my_state,my_state}
    end

    def handle_call({:add_follower,args},_from, my_state) do
        IO.puts "in add follower from mainserver"
        username = elem(args,0)
        my_name = elem(args,1)
        user_map = Map.get(my_state,"users")
        my_user = Map.get(user_map,username)
        followers_list = Map.get(my_user,"followers")
        followers_list = Enum.concat(followers_list,[my_name])

        my_user = Map.put(my_user,"followers", followers_list)
        user_map = Map.put(user_map,username,my_user)
        my_state = Map.put(my_state,"users",user_map)

        {:reply, my_state, my_state}
    end

    def handle_call({:go_offline, args}, _from, my_state) do
        IO.puts "in go_offline handle call"
        username = elem(args,0)
        user_state = GenServer.call(String.to_atom(username),{:get_user_state,{username}})

        users_map = Map.get(my_state, "users")
        IO.puts "printing user's state"
        IO.inspect users_map
        users_map = Map.put(users_map, username, user_state)
        my_state = Map.put(my_state, "users", users_map)
        IO.puts "printing server state before logging off user"
        IO.inspect my_state
        pid = Process.whereis(String.to_atom(username)) 
        GenServer.stop(pid, :normal)

        {:reply, true, my_state}
    end

    def handle_call({:add_hashtag, args}, _from, my_state) do
        IO.puts "in parse hashtag handle call"
        username = elem(args,0)
        tweet = elem(args,1)
        hashtag = elem(args,2)
        IO.puts "here"
        #new_hashtag = {tweet_id, username}
        hashtags = Map.get(my_state, "hashtags")
        IO.puts "print hashtag map"
        IO.inspect hashtags
        
        my_list = Map.get(hashtags, hashtag)
        IO.inspect my_list
        IO.puts "here2"
        if my_list == nil do
            my_list = [tweet]
        else
            my_list = [tweet|my_list]
        end
        IO.inspect my_list
        hashtags = Map.put(hashtags, hashtag, my_list)
        my_state = Map.put(my_state, "hashtags", hashtags)

        IO.puts "print mystate after hashtag"
        IO.inspect my_state
        {:reply, my_state, my_state}
    end

    def handle_call({:add_mentions, args}, _from, my_state) do
        IO.puts "in handle mention"
        tweet = elem(args,0)
        username = elem(args,1)
        mention = elem(args,2)
        mentions = Map.get(my_state, "mentions")
        my_list = Map.get(mentions, mention)
        #my_list = Enum.concat(my_list,[mention])
        if my_list == nil do
            my_list = [mention]
        else
            my_list = [mention|my_list]
        end
        IO.inspect my_list
        mentions = Map.put(mentions, mention, my_list)
        my_state = Map.put(my_state, "mentions", mentions)

        IO.puts "print mystate after mention"
        IO.inspect my_state
        {:reply, my_state, my_state}
    end

    def handle_call({:zipf, args}, _from, my_state) do
        num_users = elem(args,0)
        IO.puts "in zipf handle call"

        users_map = Map.get(my_state,"users")
        IO.inspect users_map
        distribution_list = []
        usernames = Map.keys(users_map)
        IO.inspect usernames
        #num_users = 10
        weighted_list = get_zipf_distribution(num_users)
        
        IO.puts "printing weighted list"
        IO.inspect weighted_list

        # Enum.each(usernames, fn(user) ->
        #     my_user = Map.get(users_map, user)
        #     follower_list = Map.get(my_user,"followers")
        #     num_followers = length(follower_list)
        #     new_tuple = {user, num_followers}
        #     if List.first(distribution_list) == nil do
        #         distribution_list = [new_tuple]
        #     else
        #         distribution_list = [distribution_list|new_tuple]
        #     end
        #     end)
        for i <- 0..num_users-1 do
            random_num = round(Enum.at(weighted_list,i))
            IO.inspect random_num
            followers = Enum.take_random(usernames, round(Enum.at(weighted_list,i)))
            Enum.each(followers, fn(follower) ->
                User.follow(Enum.at(usernames,i),follower)
            end)
            IO.puts "follow done: " <> Enum.at(usernames,i)
        end

        for i <-1..num_users do
            tweet = "Hi, i am a random tweet"
            user = Enum.at(usernames, i)
            for j<-1..round(Enum.at(weighted_list,i)) do
                tweet  = User.post_tweet(tweet,user)
            end
        end
        
        {:reply, my_state, my_state}

    end

    def get_zipf_distribution(numberofClients) do
        distList=[]
        s=1
        c=getConstantValue(numberofClients,s)
        distList=Enum.map(1..numberofClients,fn(x)->
            :math.ceil((c*numberofClients)/:math.pow(x,s)) 
            end)
        distList
    end

    def getConstantValue(numberofClients,s) do
        k=Enum.reduce(1..numberofClients,0,fn(x,acc)->
            :math.pow(1/x,s)+acc 
            end )
        k=1/k
        k
    end

end