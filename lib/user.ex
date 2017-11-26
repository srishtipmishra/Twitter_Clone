defmodule User do
    use GenServer 

    def start_link(username,password) do
        user = %{:username => username, :password => password, :tweets => [()], :followers => [], :following => [], :dashboard => [], name: :"#{username}"}
        {:ok,initial_state} = GenServer.start_link(User, [user],name: :"#{username}")
    end

    def init(initial_data) do
        {:ok,initial_data}
    end

    def get_state(username) do
        user_pid = GenServer.whereis(:"#{username}")
        my_state = GenServer.call(user_pid,{:get_state})
        my_state
    end

    def handle_call(:get_state,_from,my_state) do
        {:reply,my_state,my_state}
    end

    def tweet(tweet,username) do
        pid = GenServer.whereis(:"#{username}")

        #add the tweet to the user's tweet list'
        GenServer.call(pid, {:tweet,tweet})
    end

    def handle_call({:tweet, tweet, username}, current_state) do
        current_state = get_state(username)
        tweets_list = Map.fetch(current_state, "tweets")
        [h|t] = tweets_list
        new_tweet_id = elem(t,0) + 1

        new_tweet = {new_tweet_id,tweet,:os.system_time(:millisecond)}
        new_state = Map.put(current_state, "tweets", new_tweet)

        {:reply, new_state, new_state}
    end

    def follow(username, my_name) do
        #update my following list for me
        my_state = get_state(my_name)
        my_pid = GenServer.whereis(:"#{my_name}")
        new_state = GenServer.call(my_pid, {:add_to_following,username,my_name})

        #update the user's followers list
        pid = GenServer.whereis(:"#{username}")
        if pid == nil do
            MainServer.add_follower(username, my_name)
        else
            GenServer.call(pid, {:add_to_follower,username,my_name})
        end
    end

    def handle_call(:add_to_following, username, my_name,my_state) do
        following_list = Map.fetch(:"#{my_name}","following") ++ username
        new_state = Map.put(:"#{my_name}", "following", following_list)
        {:reply,new_state}
    end

    def handle_call(:add_to_follower, username, my_name,my_state) do
        follower_list = Map.fetch(:"#{username}","followers") ++ my_name
        new_state = Map.put(:"#{username}", "followers", follower_list) 
        {:reply,new_state}   
    end

    def retweet(username,tweet, tweet_id, my_name) do
        
    end

    def go_offline(username) do
        #user_state = MainServer.get_user_state(username)
        user_state = get_state(username)
        pid = GenServer.whereis("username")
    end

    def go_online(user_state,username,password) do
        pid = start_link(username,password)
        #pid = GenServer.whereis(:"#{username}")

        #check if the state of user from mainserver has data or if this is first login
        tweet_list = Map.fetch(user_state,"tweets")
        followers_list = Map.fetch(user_state,"followers")
        following_list = Map.fetch(user_state,"following")
        if Enum.count(tweet_list) != 0 || Enum.count(followers_list) != 0 || Enum.count(following_list) != 0 do
            tweets_list = create_dashboard(user_state, username)
            tweet_list = tweet_list ++ Map.fetch(:"#{username}","tweets")
            Map.put(user_state,"dashboard", tweet_list)
        end
        GenServer.call(pid, {:go_online, user_state, username})
    end

    def handle_call({:go_online, user_state, username}, my_state) do
        {:reply, user_state}
    end

    def create_dashboard(user_state, username) do
        tweets_list = []
        following_list = Map.fetch(user_state,"following_list")
        Enum.each(following_list, fn(user) -> 
            pid = GenServer.whereis(:"#{user}")
            {tweets}= GenServer.call(pid,{:get_tweets})
            tweets_list = tweets_list ++ tweets
        end)
        tweets_list
    end

    def handle_call({:get_tweets ,new_message}, _from, userState) do
        if userState != nil do
            tweets = Map.get(userState, "tweets")
        end
        {:reply,tweets, userState}
    end

end