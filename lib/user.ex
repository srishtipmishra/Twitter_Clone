defmodule User do
    use GenServer 

    def main() do
        server = "server@" <> get_ip_addr()
        client = "client@" <> get_ip_addr()
        Node.start(String.to_atom(client))
        Node.set_cookie :"srishti"
        Node.connect(String.to_atom(server))
        IO.inspect Node.list
        test_func()
    end

    def test_func() do
        users = [{"sri","mis"},{"abhi","mis"},{"karan","mis"},{"keyur","mis"},{"aru","mis"}]
        Enum.each users, fn user-> username = elem(user,0) 
                               password = elem(user,1) 
                               create_user(username,password) 
                     end
        #check to register an existing username, should prompt user exists
        create_user("keyur", "mis")

        #login
        go_online("sri","mis")
        go_online("abhi","mis")
        go_online("karan","mis")
        go_online("keyur","mis")
        go_online("aru","mis")

        #user goes offline
        #go_offline("keyur")
        #user goes online/login

        #tweet random stuff
        post_tweet("#hello, this @is my first tweet", "sri")

        follow("sri", "karan")
        follow("sri", "keyur")
        post_tweet("hello, this is my second tweet", "sri")
        post_tweet("hello, Karan's #first tweet", "karan")
        post_tweet("hello, Karan's #second tweet", "karan")
        post_tweet("hello, Karan's 3rd tweet", "karan")

        post_tweet("hello, keyur's first tweet", "keyur")
        post_tweet("hello, @abhi's first tweet", "abhi")

        #follow other users
        follow("karan", "keyur")

        #retweet one from your dashboard
        retweet(0, "karan", "sri")

        #query on a hasgtag
        
        #go offline
        offline("sri")
        follow("sri","keyur")
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

    def start_link(username,password) do
        IO.inspect username
        GenServer.start_link(User, {username,password},name: String.to_atom(username))
    end

    def init(args) do
        username = elem(args,0)
        password = elem(args,1)
        initial_data = %{"username" => username, "password" => password, "tweets" => [], "followers" => [], "following" => [], "dashboard" => []}
        {:ok,initial_data}
    end

    def create_user(username,password) do
        #access main server's user list to check if this user already exists
        user_exists = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:check_user,{username}})
        IO. inspect user_exists
        if user_exists == false do
            user = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_new_user, {username, password}})
        end
    end

    def go_online(username,password) do 
        user_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_user_state, {username}})
        #User.go_online(user_state,username,password)
        pid = User.start_link(username,password)
        IO.inspect pid
        IO.puts "--------"
        IO.inspect username
        GenServer.call(String.to_atom(username),{:go_online, {username, password}})
    end

    def post_tweet(tweet, username) do
        IO.inspect username
        user_state = GenServer.call(String.to_atom(username), {:tweet, {tweet, username}})
    end

    def follow(username, my_name) do
        GenServer.call(String.to_atom(my_name), {:follow,{username, my_name}})
    end

    def go_offline(username) do
        
    end

    def handle_call({:go_offline,args},_from, my_state) do
        #IO.puts "in go_offline wrapper"
        username = elem(args,0)
        if pid = Process.whereis(String.to_atom(username)) != nil do
        logout = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:go_offline, {username}})   
        
        if pid = Process.whereis(String.to_atom(username)) == nil do
            IO.puts "Successfully logged out"
        else
            IO.puts "could not log out"
        end
        else
        IO.puts "You're offline'"
    end
    {:reply, my_state, my_state}
    end

    def retweet(tweet_id, username, my_name) do
        User.retweet(tweet_id, username, my_name)
    end

    def create_numbered_users(num_users) do
        for i <-1..num_users do
        prefix = "user"
        username = prefix<>to_string(i)
        password = prefix<>to_string(i)
        user_exists = MainServer.check_user(username)
        if user_exists == false do
            user_pid = User.start_link(username,password)
            MainServer.create_user(username)
            IO.puts "user created" <> username
        end
        end
        GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:zipf,{num_users}})

    end

    def handle_call({:go_online, args}, _from, my_state) do
        username = elem(args,0)
        password = elem(args,1)
        IO.puts "user online: "<> username
        user_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:get_user_state,{username}})
        IO.inspect user_state
        tweets = Map.get(user_state, "tweets")
        followers = Map.get(user_state,"followers")
        following = Map.get(user_state, "following")
        if following != nil do
            Enum.each(following, fn(user) ->
                GenServer.call(String.to_atom(username),{:create_dashboard, {user}})
            end)
        end
        my_state = user_state
        {:reply, my_state, my_state}
    end

    def handle_call({:tweet, args},_from, my_state) do
        IO.puts "in post tweet handle call"

        tweet = elem(args,0)
        username = elem(args,1)
        IO.inspect username
        IO.inspect tweet

        tweets_list = Map.get(my_state, "tweets")
        IO.inspect tweets_list
        if List.first(tweets_list) == nil do
            last_id = -1
        else
            last_id = elem(List.first(tweets_list),0)
        end
        IO.puts "here1"
        new_tweet_id = last_id + 1
        new_tweet = {new_tweet_id, tweet,:os.system_time(:millisecond),username}
        IO.puts "here"
        if tweets_list == nil do 
            tweets_list = [new_tweet]
        else
            tweets_list = [new_tweet|tweets_list]
        end

        my_state = Map.put(my_state, "tweets", tweets_list)
        my_dashboard = Map.get(my_state, "dashboard")
        IO.inspect my_state
        IO.puts "here"
        IO.inspect my_dashboard
        IO.inspect new_tweet
        my_dashboard = Enum.concat([new_tweet],my_dashboard)
        my_state = Map.put(my_state,"dashboard",my_dashboard)
        IO.inspect my_state

        #add this tweet to follower's dashboard'
        IO.puts "updating dashboard for every follower"
        follower_list = Map.get(my_state, "followers")
        Enum.each(follower_list, fn(follower) ->
            GenServer.call(String.to_atom(follower), {:update_dashboard, {new_tweet}})
        end)
        
        parse_hashtag(new_tweet,username)
        parse_mentions(new_tweet,username)
        {:reply, my_state, my_state}
    end

    def handle_call({:follow, args}, _from, my_state) do
        username = elem(args,0)
        my_name = elem(args,1)
        #update my following list for me
        IO.puts "in user's follow"
        following_list = Map.get(my_state,"following") 
        IO.inspect following_list
        if Enum.member?(following_list,username) do
            IO.puts "already following"
            false
        else
            following_list = Enum.concat([username],following_list)
            my_state = Map.put(my_state, "following", following_list)

            #update the user's followers list
            pid = GenServer.whereis(String.to_atom(username))
            if pid == nil do
                GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:add_follower,{username, my_name}})
            else
                GenServer.call(String.to_atom(username),{:add_to_follower,{username, my_name}})
            end
            
            #update my dashboard with user's tweets'
            my_dashboard = Map.get(my_state, "dashboard")
            followee_tweets = GenServer.call(String.to_atom(username),{:get_tweets, {}})
            my_dashboard = Enum.concat(my_dashboard,followee_tweets)

            my_state = Map.put(my_state, "dashboard", my_dashboard)
            IO.puts "my state after following a user: "
            IO.inspect my_state
        end
        
        {:reply, my_state, my_state}
    end

    def handle_call({:add_to_follower, args}, _from ,my_state) do
        
        username = elem(args,0)
        my_name = elem(args,1)

        follower_list = Map.get(my_state,"followers")
        if List.first(follower_list) == nil do
            follower_list = [my_name]
        else
            follower_list = [my_name|follower_list]    
        end
        my_state = Map.put(my_state, "followers", follower_list) 
        IO.puts "check follower's list after adding follower'"
        IO.inspect my_state
        
        {:reply,my_state, my_state}   
    end

    def handle_call({:create_dashboard, args}, _from, my_state) do
        username = elem(args,0)
        my_dashboard = Map.get(my_state, "dashboard")
    
        tweets = GenServer.call(String.to_atom(username),{:get_tweets, {username}})
        my_dashboard = Enum.concat(my_dashboard,tweets)
        IO.puts "dashboard bulk update"
        IO.inspect my_dashboard
        my_state = Map.put(my_state, "dashboard", my_dashboard)
        IO.inspect my_state
        {:reply, my_state, my_state}
    end

    def handle_call({:update_dashboard, args}, _from, my_state) do
        IO.puts "in new update call"
        tweet = [elem(args,0)]
        my_dashboard = Map.get(my_state, "dashboard")
        my_dashboard = Enum.concat(my_dashboard,tweet)
        IO.puts "dashboard single tweet update"
        IO.inspect my_dashboard
        my_state = Map.put(my_state, "dashboard", my_dashboard)
        {:reply, my_state, my_state}
    end

    def handle_call({:get_tweets ,args}, _from, user_state) do
        #IO.puts "in get tweets list"
        if user_state != nil do
            tweets = Map.get(user_state, "tweets")
        end
        {:reply, tweets, user_state}
    end

    def handle_call({:retweet, args}, _from, my_state) do
        IO.puts "in retweet handle call"
        username = elem(args,0)
        tweet_id = elem(args,1)
        my_name = elem(args,2)
        tweet_list = Map.get(my_state,"tweets")
        if List.first(tweet_list) == nil do
            last_tweet_id = -1 
        else
            last_tweet_id = elem(List.first(tweet_list),0)
        end
        new_tweet_id = last_tweet_id + 1

        user_state = get_state(username)
        tweets = GenServer.call(String.to_atom(username), {:get_tweets, user_state})
        tweet = elem(Enum.at(Enum.reverse(tweets), tweet_id),1)
        IO.puts "printing tweet string before retweeting"
        IO.inspect tweet
        if tweet != nil do
            new_tweet = {new_tweet_id, tweet,:os.system_time(:millisecond),my_name, username}

            IO.puts "my tweet::" 
            IO.inspect new_tweet
            tweet_list = Enum.concat([new_tweet],tweet_list)

            my_state = Map.put(my_state, "tweets", tweet_list)

            #update my dashboard
            my_dashboard = Map.get(my_state, "dashboard")
            my_dashboard = Enum.concat([new_tweet],my_dashboard)
            my_state = Map.put(my_state,"dashboard",my_dashboard)
            IO.inspect my_state

            #update dashboards of my followers
            IO.inspect "updating dashboard for every follower"
            follower_list = Map.get(my_state, "followers")
            Enum.each(follower_list, fn(follower) ->
                GenServer.call(String.to_atom(follower), {:update_dashboard, {new_tweet}})
            end)
        end
        parse_hashtag(new_tweet,username)
        parse_mentions(new_tweet,username)
        {:reply, my_state, my_state}

    end

    def parse_hashtag(new_tweet, username) do
        IO.puts "in parse"
        tweet = elem(new_tweet,1)
        IO.inspect tweet
        tweet
        words = String.split(tweet, " ", trim: true)
        Enum.each(words, fn(word) ->
            if String.at(word,0) == "#" do
                GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_hashtag, {username, new_tweet, word}})
            end
        end)
    end

    def parse_mentions(new_tweet, username) do
        tweet = elem(new_tweet,1)
        words = String.split(tweet, " ", trim: true)
        Enum.each(words, fn(word) ->
            if String.at(word,0) == "@" do
                GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_mentions, {username, tweet, word}})
            end
        end)
    end

    def get_state(username) do
        my_state = GenServer.call(String.to_atom(username),{:get_user_state, username})
        my_state
    end

    def handle_call({:get_user_state ,username},_from,my_state) do          
        {:reply,my_state,my_state}
    end

    def retweet(tweet_id,username, my_name) do
        pid = Process.whereis(String.to_atom(my_name))
        if pid != nil do
            GenServer.call(pid, {:retweet, {username, tweet_id, my_name}})
        else
            false
        end
    end    
end
    # def go_offline({:go_offline,args},_from, my_state) do
    #     username = elem(args,0)
    #     #user_state = MainServer.get_user_state(username)
    #     #IO.puts "in user's go offline'"
    #     #user_state = get_state(username)
    #     #IO.puts "checking user's state'"
    #     #IO.inspect user_state
    #     logout = GenServer.call(String.to_atom("mainserver"),{:go_offline, {username, my_state}})
    #     {:reply,my_state,my_state}
    # end

    
    #def create_dashboard()
    
    # def update_followers_dashboard(user_state, username) do
    #     IO.puts "updating followers' dashboard'"
         
    #     followers_list = Map.get(user_state,"followers")
    #     Enum.each(followers_list, fn(follower) -> 
    #         pid = Process.whereis(String.to_atom(follower))
    #         tweets= GenServer.call(pid,{:get_tweets,{}})
    #         IO.puts "lets check tweet list"
    #         IO.inspect tweets
    #         GenServer.call(String.to_atom(follower), {:update_my_dashboard, {tweets}})
    #     end)
    # end

    # def handle_call({:update_my_dashboard, args}, _from, my_state) do
    #     IO.puts "updating user's dash handle call "
    #     tweets = elem(args,0)
    #     IO.inspect tweets
    #     my_dashboard = Map.get(my_state, "dashboard")
    #     IO.puts "----####----"
    #     IO.inspect my_dashboard
    #     if List.first(my_dashboard) == nil do
    #         my_dashboard = Enum.concat(my_dashboard,tweets)
    #     else
    #         my_dashboard = Enum.concat(my_dashboard,tweets)
    #     end
    #     IO.puts "check dashboard"
    #     IO.inspect my_dashboard
        

    #     my_state = Map.put(my_state, "dashboard", my_dashboard)
    #     IO.puts "check state after updating dashboard"
    #     IO.inspect my_state
    #     {:reply, my_state, my_state}    
    # end

    # def handle_call({:add_to_following, args},_from, my_state) do
    #     #IO.puts "add to following handle call"
    #     username = elem(args,0)
    #     my_name = elem(args, 1)
    #     following_list = Map.get(my_state,"following") 
    #     if following_list == nil do
    #         following_list = [username]
    #     else
    #         following_list = [username|following_list]
    #     end
    #     my_state = Map.put(my_state, "following", following_list)
    #     #IO.puts "check state after updating following list"
    #     #IO.inspect my_state
    #     {:reply,my_state, my_state}
    # end

    

