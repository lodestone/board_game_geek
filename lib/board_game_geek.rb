require "bundler/setup"
require "nokogiri"
require "open-uri"
require "ostruct"

module BoardGameGeek

  class Game < OpenStruct
  end

  class Games

    TOP_GAMES_URI          = "http://boardgamegeek.com/browse/boardgame/page/"
    ABSTRACT_GAMES_URI     = "http://boardgamegeek.com/abstracts/browse/boardgame/"
    CHILDRENS_GAMES_URI    = "http://boardgamegeek.com/childrensgames/browse/boardgame/"
    CUSTOMIZABLE_GAMES_URI = "http://boardgamegeek.com/cgs/browse/boardgame/"
    FAMILY_GAMES_URI       = "http://boardgamegeek.com/familygames/browse/boardgame/"
    PARTY_GAMES_URI        = "http://boardgamegeek.com/partygames/browse/boardgame/"
    STRATEGY_GAMES_URI     = "http://boardgamegeek.com/strategygames/browse/boardgame/"
    THEMATIC_GAMES_URI     = "http://boardgamegeek.com/thematic/browse/boardgame/"
    WAR_GAMES_URI          = "http://boardgamegeek.com/wargames/browse/boardgame/"
    GAMES_PER_PAGE         = 100
    DEFAULT_AMOUNT         = 100

    def self.games(genre=:top, how_many=DEFAULT_AMOUNT)
      send("#{genre}_games", how_many)
    end

    def self.get_games(uri, how_many)
      # break total into pages + remainder
      full_pages, remainder = self.break_down_total(how_many)
      # accumulate #{pages} calls to bgg
      # accumulate one more call(#{remainder}) to bgg

      Array.new.tap do |games|
        (1..(full_pages)).each do |page_number|
          how_many = GAMES_PER_PAGE
          how_many = remainder if page_number == full_pages && remainder > 0

          doc = Nokogiri::HTML(open "#{uri}#{page_number}.html")

          doc.css('table#collectionitems tr').each_with_index do |game_row, idx|
            next  if idx == 0
            break if idx > how_many

            begin
              cells = game_row.css("td").map(&:inner_text).map(&:strip)

              name_and_date = cells[2].to_s.split("\n")

              ranking      = cells[0]
              name         = name_and_date[0]
              release_date = name_and_date[2].to_s.strip[1..-2]
              rating       = cells[3]

              game_path = game_row.css(".collection_thumbnail a").first["href"]
              game_url = "http://boardgamegeek.com" + game_path

              image_url = game_row.css(".collection_thumbnail img").first["src"]
              image_url.sub!("_mt", "_t")

              games << Game.new(name:         name,
                                ranking:      ranking,
                                rating:       rating,
                                release_date: release_date,
                                url:          game_url,
                                image_url:    image_url)
            rescue => ex
              puts ex

              games << Game.new(name:         defined?(name)         && name         || "failed parse",
                                ranking:      defined?(ranking)      && ranking      || "failed parse",
                                rating:       defined?(rating)       && rating       || "failed parse",
                                release_date: defined?(release_date) && release_date || "failed parse",
                                url:          defined?(game_url)     && game_url     || "failed parse",
                                image_url:    defined?(image_url)    && image_url    || "failed parse")
            end
          end
        end
      end
    end

    def self.top_games(how_many=DEFAULT_AMOUNT)
      get_games(TOP_GAMES_URI, how_many)
    end

    def self.war_games(how_many=DEFAULT_AMOUNT)
      get_games(WAR_GAMES_URI, how_many)
    end

    def self.strategy_games(how_many=DEFAULT_AMOUNT)
      get_games(STRATEGY_GAMES_URI, how_many)
    end

    def self.family_games(how_many=DEFAULT_AMOUNT)
      get_games(FAMILY_GAMES_URI, how_many)
    end

    def self.abstract_games(how_many=DEFAULT_AMOUNT)
      get_games(ABSTRACT_GAMES_URI, how_many)
    end

    def self.customizable_games(how_many=DEFAULT_AMOUNT)
      get_games(CUSTOMIZABLE_GAMES_URI, how_many)
    end

    def self.childrens_games(how_many=DEFAULT_AMOUNT)
      get_games(CHILDRENS_GAMES_URI, how_many)
    end

    def self.party_games(how_many=DEFAULT_AMOUNT)
      get_games(PARTY_GAMES_URI, how_many)
    end

    def self.thematic_games(how_many=DEFAULT_AMOUNT)
      get_games(THEMATIC_GAMES_URI, how_many)
    end

    def self.break_down_total(total)
      [(total.to_f/GAMES_PER_PAGE).ceil, total%GAMES_PER_PAGE]
    end

  end

end

BGG = BoardGameGeek
