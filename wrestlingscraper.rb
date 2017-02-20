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

def each_stat(wrestler,stat)
	wrestler.each do |w|
		w[stat] = yield w[stat]
	end
end

def update_stats(wrestlers,w1,w2,show,w_match)
    wrestler1_stats = wrestlers[w1]
    wrestler2_stats = wrestlers[w2]
    
    if !wrestler1_stats[:h2h][w2] then
    	wrestler1_stats[:h2h][w2] = {
    								:ppv_matches => 0,
    								:ppv_wins => 0,
    								:ppv_dq_wins => 0,
    								:ppv_pin_wins => 0,
    								:ppv_sub_wins => 0,
    								:ppv_losses => 0,
    								:ppv_dq_losses => 0,
    								:ppv_pin_losses => 0,
    								:ppv_sub_losses => 0,
    								:ppv_draws => 0,
		        					:ppv_streak => 0,
							        :ppv_championship_wins => 0,
							        :ppv_championship_losses => 0,
							        :ppv_championship_defense_wins => 0,
	        						:ppv_championship_defense_losses => 0,
	        						:ppv_championship_challenge_wins => 0,
	        						:ppv_championship_challenge_losses => 0,
	        						:ppv_last_match => 0
	        						}
    	wrestler2_stats[:h2h][w1] = {
    								:ppv_matches=> 0,
									:ppv_wins => 0,
    								:ppv_dq_wins => 0,
    								:ppv_pin_wins => 0,
    								:ppv_sub_wins => 0,
    								:ppv_losses => 0,
    								:ppv_dq_losses => 0,
    								:ppv_pin_losses => 0,
    								:ppv_sub_losses => 0,
    								:ppv_draws => 0,
		        					:ppv_streak => 0,
							        :ppv_championship_wins => 0,
							        :ppv_championship_losses => 0,
							        :ppv_championship_defense_wins => 0,
	        						:ppv_championship_defense_losses => 0,
	        						:ppv_championship_challenge_wins => 0,
	        						:ppv_championship_challenge_losses => 0,
	        						:ppv_last_match => 0
    								}
    end
    
    wrestler1_h2h_stats = wrestler1_stats[:h2h][w2]
    wrestler2_h2h_stats = wrestler2_stats[:h2h][w1]
    
    wrestler1_stats[:ppv_last_match] = show[:date]
    wrestler1_h2h_stats[:ppv_last_match] = show[:date]
    wrestler2_stats[:ppv_last_match] = show[:date]
    wrestler2_h2h_stats[:ppv_last_match] = show[:date]
    
    w1s = [wrestler1_stats,wrestler1_h2h_stats]
    w2s = [wrestler2_stats,wrestler2_h2h_stats]
    
    each_stat(w1s + w2s,:ppv_matches) { |v|  v + 1 }
    
    if (w_match[:winner]) then
    	each_stat(w1s,:ppv_wins) { |v| v + 1 }
    	each_stat(w2s,:ppv_losses) { |v| v + 1 }
        
        each_stat(w1s,:ppv_streak) do |v|
	        if (v < 0)
	            1
	        else
	            1 + v
	        end
	    end
        
        each_stat(w2s,:ppv_streak) do |v|
	        if (v > 0)
	            -1
	        else
	            -1 + v
	        end
        end
        
        case w_match[:ending]
        when /(p|P)in/
        	each_stat(w1s,:ppv_pin_wins) { |v| v + 1 }
            each_stat(w2s,:ppv_pin_losses) { |v| v + 1 }
        when /(s|S)ub/
            each_stat(w1s,:ppv_sub_wins) { |v| v + 1 }
            each_stat(w2s,:ppv_sub_losses) { |v| v + 1 }
        when /(dq|DQ)/
            each_stat(w1s,:ppv_dq_wins) { |v| v + 1 }
            each_stat(w2s,:ppv_dq_losses) { |v| v + 1 }
        end
        
        if w_match[:title].length >= 1
        	each_stat(w1s,:ppv_championship_wins) { |v|  v + 1 }
            each_stat(w2s,:ppv_championship_losses) { |v|  v + 1 }
        
            if w_match[:current_champ] == "Wrestler 1"
            	each_stat(w1s,:ppv_championship_defense_wins) { |v| v + 1 }
            	each_stat(w2s,:ppv_championship_challenge_losses) { |v| v + 1 }
        	else
                each_stat(w1s,:ppv_championship_challenge_wins) { |v| v + 1 }
            	each_stat(w2s,:ppv_championship_defense_losses) { |v| v + 1 }
            end
        end
    else
        each_stat(w1s,:ppv_draws) { |v| v + 1 }
        each_stat(w2s,:ppv_draws) { |v| v + 1 }
    end
    
    
	#	                                            :main_event_appearances=>0,
    
end

# If you get a parsing error it's because the most recently printed wrestler
# ID has an "unknown" date.
@missing = {
		"39" => Date.parse("November 24, 1962"),
		"36" => Date.parse("October 30, 1947"),
		"116" => Date.parse("October 8, 1955"),
		"1311" => Date.parse("Aug 5, 1963"), # Arbitrary estimate, disregard in training
		"549" => Date.parse("9th September 1965"),
		"12118" => Date.parse("April 1, 1980"), # Arbitrary estimate, disregard in training
		"2072" => Date.parse("May 29, 1984")
	}
	
def init_wrestler(wrestlers,w_id)
	
	# Biographical Info
	page = Nokogiri::HTML(open("http://www.profightdb.com/wrestlers/-#{w_id}.html"))
	sleep(@crawl_wait)
	puts w_id
	
	info = page.css('table')[0]
	
	info.to_s =~ /Date (O|o)f Birth\:\<\/strong\>.*\<.*\>(.*)\<\/a\>/
	
	wrestlers[w_id][:dob] = Date.parse($2) unless @missing[w_id]
	
	if @missing[w_id] then
		wrestlers[w_id][:dob] = @missing[w_id]
	end
	
	wrestlers[w_id][:nationality] = page.css('table')[0].css('tr')[2].css('td')[0].text[-3..-1]
	
	# Rankings
	page = Nokogiri::HTML(open("http://www.profightdb.com/pwi/-#{w_id}.html"))
	puts "YO"
	sleep(@crawl_wait)
	
	rankings = page.css('.table-wrapper')[0].css('.gray')
	
	rankings_table = Hash.new({:position => 501, :change => 0})
	wrestlers[w_id][:pwi_rankings] = rankings_table
	
	rankings.each { |row|
		cols = row.css('td')
		
		year = cols[0].css('a')[0].text
		
		position = cols[1].text.strip.to_i
		
		change = cols[3].text.strip
		
		if change == "N/A" then
			change = 501-position
		else
			change = change.to_i
		end
		
		rankings_table[year.to_i] = {:position => position, :change => change}
	}
	
	
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
@crawl_wait = 5

14.downto(1) do |page|
    crawl_page(shows,"WWF",page)
    sleep(@crawl_wait)
end

21.downto(1) do |page|
    crawl_page(shows,"WWE",page)
    sleep(@crawl_wait)
end



CSV.open("ppv_data.csv","wb") {|csv|
	csv << [
	        "wrestler 1",
	        "wrestler 1 id",
	        "wrestler 1 nationality",
	        "wrestler 2",
	        "wrestler 2 id",
	        "wrestler 2 nationality",
	        "current champion",
	        "winner",
	        "match ending",
	        "card order",
	        "title",
	        "match type",
	        "date",
	        "show name",
	        "location",
	        "W1 Age",
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
	        "W1 Last PPV Match",
	        "W1 PWI Ranking",
	        "W1 PWI Change",
	        "W2 Age",
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
	        "W2 PPV Championship Challenge Losses",
	        "W2 Last PPV Match",
	        "W2 PWI Ranking",
	        "W2 PWI Change"]
	shows.each { |show|
		pwi_year = (show[:date].to_time - (60*60*24*243)).year
		
		show[:matches].each { |w_match|
		
		    if !wrestlers[w_match[:wrestler1_id]] then
		        wrestlers[w_match[:wrestler1_id]] = {
		        									:ppv_matches=>0,
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
		                                            :ppv_last_match => 0,
		                                            :main_event_appearances=>0,
		                                            :h2h=>{}
		                                            }
		    	init_wrestler(wrestlers,w_match[:wrestler1_id])
		    end
		    
		    if !wrestlers[w_match[:wrestler2_id]] then
		        wrestlers[w_match[:wrestler2_id]] = {
		        									:ppv_matches=>0,
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
		                                            :ppv_last_match => 0,
		                                            :main_event_appearances=>0,
		                                            :h2h=>{}
		                                            }
		    	init_wrestler(wrestlers,w_match[:wrestler2_id])
		    end
		
		
			csv << [
			    w_match[:wrestler1],
			    w_match[:wrestler1_id],
			    wrestlers[w_match[:wrestler1_id]][:nationality],
			    w_match[:wrestler2],
			    w_match[:wrestler2_id],
			    wrestlers[w_match[:wrestler2_id]][:nationality],
			    w_match[:current_champ],
			    w_match[:winner].to_s,
			    w_match[:ending],
			    w_match[:order],
			    w_match[:title],
			    w_match[:type],
			    show[:date],
			    show[:name],
			    show[:location],
			    (show[:date].to_time - wrestlers[w_match[:wrestler1_id]][:dob].to_time)/(60*60*24*365),
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
			    wrestlers[w_match[:wrestler1_id]][:ppv_last_match],
			    wrestlers[w_match[:wrestler1_id]][:pwi_rankings][pwi_year][:position],
			    wrestlers[w_match[:wrestler1_id]][:pwi_rankings][pwi_year][:change],
			    (show[:date].to_time - wrestlers[w_match[:wrestler2_id]][:dob].to_time)/(60*60*24*365),
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
			    wrestlers[w_match[:wrestler2_id]][:ppv_championship_challenge_losses],
			    wrestlers[w_match[:wrestler2_id]][:ppv_last_match],
			    wrestlers[w_match[:wrestler2_id]][:pwi_rankings][pwi_year][:position],
			    wrestlers[w_match[:wrestler2_id]][:pwi_rankings][pwi_year][:change]
			    ]
			    
		
		update_stats(wrestlers,w_match[:wrestler1_id], w_match[:wrestler2_id], show, w_match)
			    
		}
	}
}
