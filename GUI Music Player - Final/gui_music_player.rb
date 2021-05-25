require 'rubygems'
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)
WIDTH = 1000 
HEIGHT = 1000




# ----------------------CLASSES (RECORDS) AND ENUMERATIONS----------------------------------

# decides overlapping
module ZOrder
    BACKGROUND, MIDDLE, TOP = *0..2
  end


# song genres
module Genre
    POP, CLASSIC, JAZZ, ROCK = *1..4
end
  
$genre_names = ['Genres:', 'Pop', 'Classic', 'Jazz', 'Rock']
  

class Album

    # album attributes
    attr_accessor :title, :artist, :genre, :tracks, :id, :x, :y, :image

    # attributes initialized
    def initialize (title, artist, genre, tracks, album_id)
        @title = title
        @artist = artist
        @genre = genre
        @tracks = tracks
        @id = album_id
    end
end

class Track
    # track attributes
    attr_accessor :name, :location, :x, :y

    # attributes initialized
    def initialize (name, location)
        @name = name
        @location = location
    end
end




# -------------------------------READ ALBUM MENU METHODS--------------------------------------

# reads in a single track from the given file.
def read_track(a_file)
    
    track = Track.new(a_file.gets(), a_file.gets())
    return(track)
end

# Returns an array of tracks read from the given file
def read_tracks(a_file)
    count = a_file.gets().to_i()
    tracks = Array.new()

    index = 0
    # a loop that reads tracks and builds an array of tracks
    while (index < count)
        track = read_track(a_file)
        tracks << track
        index += 1
    end

  return(tracks)
end


# reads album information and returns the album instance
def read_album(filename)

    music_file = File.new(filename, 'r')


    albums = Array.new()

    album_count = music_file.gets().to_i()
    
    index = 0
    while (index < album_count)

        # get album details
        album_id = index
        album_artist = music_file.gets()
        album_title = music_file.gets()
        album_genre = music_file.gets()
        album_tracks = read_tracks(music_file) #reads tracks for the given file 
        album_image = Gosu::Image.new(music_file.gets().chomp())

        # constructing the album instance
        album = Album.new(album_title, album_artist, album_genre, album_tracks, album_id)
        album.title = album_title
        album.artist = album_artist
        album.genre = album_genre.chomp()
        album.tracks = album_tracks
        album.image = album_image
        album.id = album_id

        albums << album

        index += 1
    end

    return(albums)
end


class MusicPlayerMain < Gosu::Window

    # CONSTANTS
    IMAGE_POS_X = 480
    IMAGE_POS_Y = 20
    BACK_POS_X = 20
    BACK_POS_Y = 800

# --------------------------------------------INITIALIZE------------------------------------ 

	def initialize
        # window setup
	    super WIDTH, HEIGHT
	    self.caption = "Music Player"

        # initializing variables
        @albums = read_album('albums.txt')
        @track_font = Gosu::Font.new(30)
        @image = @albums[0].image
        @on_main_menu = true # boolean for when user is on main menu

        # store entity values for what is playing right now
        @current_album = @albums[0]
        @current_track
        @current_i 
    
        # setting positions for track names on the screen
        @albums.each do |album|
            y = 40
            album.tracks.each do |track|
                track.x = 45
                track.y = y
                y += 70
            end
        end

        y = 40
        # setting positions for album names on the screen
        @albums.each do |album|
            album.x = 45
            album.y = y
            y += 70
        end
	end


    def update

        # when a song finishes, switch to the next song or the first song if the last song ends
        if (!@on_main_menu)

            
            if (Gosu::Song.current_song == nil)
                if (@current_i != @current_album.tracks.length - 1)
                    @current_i += 1
                else 
                    @current_i = 0
                end

                @current_track = @current_album.tracks[@current_i]
                playTrack(@current_i, @current_album)
            end
        end
    end

    #displays album names
    def display_albums(albums) 

        if (@on_main_menu) # draw names on main menu
            albums.each do |album|
                @track_font.draw_text("#{album.title.chomp} by #{album.artist.chomp}", album.x,album.y,ZOrder::TOP,1.0, 1.0, Gosu::Color::WHITE)
            end
        end
    end

    # displays track names
    def draw_tracks(album)

        if (!@on_main_menu) # draw track names if not on main menu

            album.tracks.each_with_index do |track, i|

            @track_font.draw_text("#{i}: #{track.name}" , track.x, track.y, ZOrder::TOP, 1, 1, Gosu::Color::WHITE)

            end
        end
    end


    # plays a track depending on track number in an album
    def playTrack(track, album)
        @song = Gosu::Song.new(album.tracks[track].location.chomp())
        @song.play(false)
    end

    # Draw a coloured background using TOP_COLOR and BOTTOM_COLOR
	def draw_background()
        draw_rect(0,0,WIDTH,HEIGHT,BOTTOM_COLOR,ZOrder::BACKGROUND, mode = :default)
	end


# --------------------------------------------DRAW------------------------------------ 

	def draw
        # draw UI
		draw_background()
        display_albums(@albums)
        draw_tracks(@current_album)
        @image.draw(IMAGE_POS_X,IMAGE_POS_Y,ZOrder::TOP,1,1)
        @track_font.draw_text('<-BACK', BACK_POS_X, BACK_POS_Y, ZOrder::TOP, 1, 1, Gosu::Color::WHITE)

        # if not on main menu and on the current album's page, highlight the track playing with an >
        if (!@on_main_menu)
            if (@current_album.tracks.include? @current_track)
                @track_font.draw_text('>', @current_track.x - 20, @current_track.y, 1, 1, 1, Gosu::Color::WHITE)
            end
        end

	end

 	def needs_cursor?; true; end

# ----------------------------------------------------BUTTON CLICKS---------------------------


     # what happens when the left mouse button is clicked?
	def button_down(id)
		case id
	    when Gosu::MsLeft

            # what happens on the main menu?
            if (@on_main_menu)
                @albums.each do |album|
                    # when an album title is clicked, draw album image and switch to tracks page
                    if mouse_x > album.x  and mouse_x < album.x + 400
                        if mouse_y < album.y + 20 and mouse_y > album.y
                            @image = album.image
                            
                            # change current entity values
                            @current_album = album
                            @current_track = @current_album.tracks[0]
                            @current_i = 0
                            
                            playTrack(@current_i,@current_album) # starts playing the first album track when an album name is clicked
                            @on_main_menu = false # switch to tracks page

                        end
                    end
                end
            else
                @current_album.tracks.each_with_index do |track,i|
                    if mouse_x > track.x  and mouse_x < track.x + 200
                        if mouse_y < track.y + 20 and mouse_y > track.y
                            
                            puts('Track was changed')
                            playTrack(i, @current_album)
                            
                            # changing current entity values
                            @current_track = track
                            @current_i = i
                        end
                    end
                end

            end



            # what happens on the track page?
            # play the track the user clicks on when on a track page



            # BACK button takes back to the Main Menu
            if mouse_x > BACK_POS_X and mouse_x < (BACK_POS_X + 100)
                if mouse_y > BACK_POS_Y and mouse_y < (BACK_POS_Y + 30)
                    @on_main_menu = true
                    
                end
            end
	    end
	end

end

# Show is a method that loops through update and draw

MusicPlayerMain.new.show if __FILE__ == $0
