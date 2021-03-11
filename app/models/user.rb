class User < ActiveRecord::Base
    has_many :user_activities
    has_many :activities, through: :user_activities
    has_many :bookmarks
    has_many :favorites, through: :bookmarks, source: :activity


    def self.login
        prompt = TTY::Prompt.new
        username = prompt.ask("Please enter your username:")
        password = prompt.mask("Please enter your password:")

        user = User.find_by(username: username, password: password)

        until user 
            # system "clear"
            puts "Incorrect username or password"
            user = User.login 
        end
        user
    end

    def self.register
        prompt = TTY::Prompt.new
        username = prompt.ask("Please enter your desired username:")
        user = User.find_by(username: username)

        until !user
            puts "Sorry this username has been taken. Please chooose another one!"
            user = User.register
        end

        password = prompt.mask("Please enter your password:")

        # password_confirm = prompt.mask("Please confirm your password:")

        # until password == password_confirm
        #     puts "Your passwords did not match. Please try registering again."
        #     user = User.register
        # end

        name = prompt.ask("What would you like to be called?")

        new_user = User.create(username: username, password: password, name: name)
    end

    def self.browse_past_activities(session)
        system "clear"
        prompt = TTY::Prompt.new
        user = session.user

        prompt.select("What would you like to see?") do |menu|
            menu.choice "Number of each activity completed", -> {user.activities_by_frequency(session)}
            menu.choice "Log of all past activities", -> {user.activities_log(session)}
            menu.choice "Return to Main Menu", -> {session.main_menu}
        end

    end

    def log_activity(activity, session)    
        UserActivity.create(user_id: self.id, activity_id: activity.id)
        
        accolades = ["Excellent work!", "Great job!", "High-five!", "Self-care ftw!"]
        puts accolades.sample

        session.prompt.select("What would you like to do?") do |menu|
            menu.choice "Save this activity to your Bookmarks", -> {Bookmark.favorite(activity,session)}
            menu.choice "Return to Main Menu", -> {session.main_menu}
            menu.choice "Exit app", -> {session.exit_app}
        end
    end

    def activities_log(session)
        user_activities.each do |logged_activity|
            puts "#{logged_activity.activity.name} on #{logged_activity.date}"
        end

        session.prompt.keypress("Press any key to return to previous menu")
        User.browse_past_activities(session)

    end

    def activities_by_frequency(session)
        activity_count = activities.group(:name).count
        list = activity_count.sort_by{|activity, count| count}.reverse
        list.each do |list_pair|
            puts "#{list_pair[0]} -> #{list_pair[1]}".colorize(:light_green).italic
        end
        session.prompt.keypress("Press any key to return to the main menu")
        session.main_menu
    end

    def show_favorites(session)
       options = self.favorites.map {|activity| activity.name}.sort.uniq
       options.push(" Exit to main menu")
       bookmark_choice = session.prompt.select("Which activity would you like to look at?") do |menu|
            menu.help "(Use ↑/↓ and ←/→ arrow keys, press Enter to select)"
            menu.show_help :always
            menu.choices options
       end
        
       activity = Activity.find_by(name: bookmark_choice)
       current_bookmark = Bookmark.find_by(user_id: self.id, activity_id: activity.id)
       if bookmark_choice == nil
            session.main_menu
        end

        current_bookmark.bookmark_options(session)
    end


    # def remove_bookmark(session)
    #     delete = 
    #      session.prompt.yes?("Are you sure you want to remove this activity from your bookmark?") do |q|
    #         q.suffix "Yes / No"
            

    #     end
    # end


    



end

