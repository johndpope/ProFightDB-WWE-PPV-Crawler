require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'

def initial_query(company,page,ppv)
    if ppv then
        ppv = "yes"
    else
        ppv = "no"
    end
    
    case company
    when "WWF"
        "http://www.profightdb.com/cards/wwf-cards-pg#{page}-#{ppv}-1.html?order=&type="
    when "WWE"
        "http://www.profightdb.com/cards/wwe-cards-pg#{page}-#{ppv}-2.html?order=&type="
    end
    
end

def update_stats(wrestlers,w1,w2,show,w_match)
    wrestler1_stats = wrestlers[w1]
    wrestler2_stats = wrestlers[w2]
    
    if (w_match[:winner]) then
        wrestler1_stats[:ppv_wins] = wrestler1_stats[:ppv_wins] + 1
        wrestler2_stats[:ppv_losses] = wrestler2_stats[:ppv_losses] + 1
        
        if (wrestler1_stats[:ppv_streak] < 0)
            wrestler1_stats[:ppv_streak] = 1
        else
            wrestler1_stats[:ppv_streak] = 1 + wrestler1_stats[:ppv_streak]
        end
        
        if (wrestler2_stats[:ppv_streak] > 0)
            wrestler2_stats[:ppv_streak] = -1
        else
            wrestler2_stats[:ppv_streak] = -1 + wrestler2_stats[:ppv_streak]
        end
        
        case w_match[:ending]
        when /(p|P)in/
            wrestler1_stats[:ppv_pin_wins] = wrestler1_stats[:ppv_pin_wins] + 1
            wrestler2_stats[:ppv_pin_losses] = wrestler2_stats[:ppv_pin_losses] + 1
        when /(s|S)ub/
            wrestler1_stats[:ppv_sub_wins] = wrestler1_stats[:ppv_sub_wins] + 1
            wrestler2_stats[:ppv_sub_losses] = wrestler2_stats[:ppv_sub_losses] + 1
        when /(dq|DQ)/
            wrestler1_stats[:ppv_dq_wins] = wrestler1_stats[:ppv_dq_wins] + 1
            wrestler2_stats[:ppv_dq_losses] = wrestler2_stats[:ppv_dq_losses] + 1
        end
        
        if w_match[:title].length >= 1
            wrestler1_stats[:ppv_championship_wins] = wrestler1_stats[:ppv_championship_wins] + 1
            wrestler2_stats[:ppv_championship_losses] = wrestler2_stats[:ppv_championship_losses] + 1
        
            if w_match[:current_champ] == "Wrestler 1"
                wrestler1_stats[:ppv_championship_defense_wins] = wrestler1_stats[:ppv_championship_defense_wins] + 1
                wrestler2_stats[:ppv_championship_challenge_losses] = wrestler2_stats[:ppv_championship_challenge_losses] + 1
            else
                wrestler1_stats[:ppv_championship_challenge_wins] = wrestler1_stats[:ppv_championship_challenge_wins] + 1
                wrestler2_stats[:ppv_championship_defense_losses] = wrestler2_stats[:ppv_championship_defense_losses] + 1
            end
        end
    else
        wrestler1_stats[:ppv_draws] = wrestler1_stats[:ppv_draws] + 1
        wrestler2_stats[:ppv_draws] = wrestler2_stats[:ppv_draws] + 1
    end
    
    
	#	                                            :main_event_appearances=>0,
	#	                                            :h2h=>{}
    
end


def crawl_page(shows,company,page)
    page = Nokogiri::HTML(open(initial_query(company,page,true)))
    
    page.css('.table-wrapper')[0].css('table')[0].css('tr').reverse[0..(-2)].each { |row| 
        date, company, show_name, location = row.css('td').map { |col|
            col.css('a')[0].text
        }
        
        show_page = "http://www.profightdb.com" + row.css('td')[2].css('a')[0].attribute_nodes[0].value
        
        puts show_page
        puts company.inspect
        puts date.inspect
        puts show_name.inspect
        puts location.inspect
        puts
        
        show = {:date => Date.parse(date), :name => show_name, :location => location}
        matches = []
        
        match_page = Nokogiri::HTML(open(show_page))
        
        match_page.css('.table-wrapper')[0].css('table')[0].css('tr')[1..(-1)].each { |mrow|
            col_num = 0
            
            current_champ = "None"
            
            wrestlerid = []
            order, wrestler1, ending, wrestler2, duration, type, title, rating = mrow.css('td').map { |mcol|
                
                col_num = col_num + 1
                
                case col_num
                when 1
                    mcol.text.chomp
                when 3
                    mcol.text.chomp
                when 5
                    mcol.text.chomp
                when 6
                    mcol.text.chomp
                when 7
                    mcol.text.gsub(/\((T|t)itle (C|c)hange\)/,"").chomp
                when 8
                    mcol.text.chomp
                else
                    if mcol.css('a').size == 1 then
                        if mcol.text =~ /(\((C|c)\))/ 
                            current_champ = "Wrestler #{col_num/2}"
                        end
                        
                        mcol.css('a')[0].attribute_nodes[0].value =~ /(\d+)\.html/
                        
                        wrestlerid[col_num/2 - 1] = $1
                        
                        mcol.css('a')[0].text.chomp
                    else
                        nil
                    end
                end
            }
            
            winner_present = false
            
            if ending =~ /ef\. \((.*)\)/ || ending =~ /def/
                winner_present = true
                ending = $1
                puts "winner"
            else
                puts ending
                ending =~ /raw \((.*)\)/
                ending = $1
                puts "draw"
            end
            
            
            type = "" unless type[0].ord != 160
            
            matches << {:wrestler1 => wrestler1, :order => order, :ending => ending,
                :winner => winner_present, :wrestler2 => wrestler2, :type => type,
                :title => title, :current_champ => current_champ,
                :wrestler1_id => wrestlerid[0], :wrestler2_id => wrestlerid[1]
            } unless (!wrestler1 || !wrestler2)
            
        }
        
        show[:matches] = matches
        shows << show
    }
end


wrestlers = {}


shows = []

14.downto(1) do |page|
    crawl_page(shows,"WWF",page)
    sleep(5)
end

21.downto(1) do |page|
    crawl_page(shows,"WWE",page)
    sleep(5)
end



CSV.open("ppv_data.csv","wb") {|csv|
	csv << [
	        "wrestler 1",
	        "wrestler 1 id",
	        "wrestler 2",
	        "wrestler 2 id",
	        "current champion",
	        "winner",
	        "match ending",
	        "card order",
	        "title",
	        "match type",
	        "date",
	        "show name",
	        "location",
	        "W1 PPV Wins",
	        "W1 PPV DQ Wins",
	        "W1 PPV Pin Wins",
	        "W1 PPV Sub Wins",
	        "W1 PPV Losses",
	        "W1 PPV DQ Losses",
	        "W1 PPV Pin Losses",
	        "W1 PPV Sub Losses",
	        "W1 PPV Draws",
	        "W1 PPV Streak",
	        "W1 PPV Championship Wins",
	        "W1 PPV Championship Losses",
	        "W1 PPV Championship Defense Wins",
	        "W1 PPV Championship Defense Losses",
	        "W1 PPV Championship Challenge Wins",
	        "W1 PPV Championship Challenge Losses",
	        "W2 PPV Wins",
	        "W2 PPV DQ Wins",
	        "W2 PPV Pin Wins",
	        "W2 PPV Sub Wins",
	        "W2 PPV Losses",
	        "W2 PPV DQ Losses",
	        "W2 PPV Pin Losses",
	        "W2 PPV Sub Losses",
	        "W2 PPV Draws",
	        "W2 PPV Streak",
	        "W2 PPV Championship Wins",
	        "W2 PPV Championship Losses",
	        "W2 PPV Championship Defense Wins",
	        "W2 PPV Championship Defense Losses",
	        "W2 PPV Championship Challenge Wins",
	        "W2 PPV Championship Challenge Losses"]
	shows.each { |show|
		show[:matches].each { |w_match|
		
		    if !wrestlers[w_match[:wrestler1_id]] then
		        wrestlers[w_match[:wrestler1_id]] = {
		                                            :ppv_wins=>0,
		                                            :ppv_dq_wins=>0,
		                                            :ppv_pin_wins=>0,
		                                            :ppv_sub_wins=>0,
		                                            :ppv_losses=>0,
		                                            :ppv_dq_losses=>0,
		                                            :ppv_pin_losses=>0,
		                                            :ppv_sub_losses=>0,
		                                            :ppv_draws=>0,
		                                            :ppv_streak=>0,
		                                            :ppv_championship_wins=>0,
		                                            :ppv_championship_losses=>0,
		                                            :ppv_championship_defense_wins=>0,
		                                            :ppv_championship_defense_losses=>0,
		                                            :ppv_championship_challenge_wins=>0,
		                                            :ppv_championship_challenge_losses=>0,
		                                            :main_event_appearances=>0,
		                                            :h2h=>{}
		                                            }
		    end
		    
		    if !wrestlers[w_match[:wrestler2_id]] then
		        wrestlers[w_match[:wrestler2_id]] = {
		                                            :ppv_wins=>0,
		                                            :ppv_dq_wins=>0,
		                                            :ppv_pin_wins=>0,
		                                            :ppv_sub_wins=>0,
		                                            :ppv_losses=>0,
		                                            :ppv_dq_losses=>0,
		                                            :ppv_pin_losses=>0,
		                                            :ppv_sub_losses=>0,
		                                            :ppv_draws=>0,
		                                            :ppv_streak=>0,
		                                            :ppv_championship_wins=>0,
		                                            :ppv_championship_losses=>0,
		                                            :ppv_championship_defense_wins=>0,
		                                            :ppv_championship_defense_losses=>0,
		                                            :ppv_championship_challenge_wins=>0,
		                                            :ppv_championship_challenge_losses=>0,
		                                            :main_event_appearances=>0,
		                                            :h2h=>{}
		                                            }
		    end
		
		    update_stats(wrestlers,w_match[:wrestler1_id], w_match[:wrestler2_id], show, w_match)
		
			csv << [
			    w_match[:wrestler1],
			    w_match[:wrestler1_id],
			    w_match[:wrestler2],
			    w_match[:wrestler2_id],
			    w_match[:current_champ],
			    w_match[:winner].to_s,
			    w_match[:ending],
			    w_match[:order],
			    w_match[:title],
			    w_match[:type],
			    show[:date],
			    show[:name],
			    show[:location],
			    wrestlers[w_match[:wrestler1_id]][:ppv_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_dq_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_pin_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_sub_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_losses],
			    wrestlers[w_match[:wrestler1_id]][:ppv_dq_losses],
			    wrestlers[w_match[:wrestler1_id]][:ppv_pin_losses],
			    wrestlers[w_match[:wrestler1_id]][:ppv_sub_losses],
			    wrestlers[w_match[:wrestler1_id]][:ppv_draws],
			    wrestlers[w_match[:wrestler1_id]][:ppv_streak],
			    wrestlers[w_match[:wrestler1_id]][:ppv_championship_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_championship_losses],
			    wrestlers[w_match[:wrestler1_id]][:ppv_championship_defense_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_championship_defense_losses],
			    wrestlers[w_match[:wrestler1_id]][:ppv_championship_challenge_wins],
			    wrestlers[w_match[:wrestler1_id]][:ppv_championship_challenge_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_dq_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_pin_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_sub_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_dq_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_pin_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_sub_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_draws],
			    wrestlers[w_match[:wrestler2_id]][:ppv_streak],
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_defense_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_defense_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_challenge_wins],
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_challenge_losses]
			    ]
			    
		}
	}
}
