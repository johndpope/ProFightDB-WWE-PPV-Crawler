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

def init_wrestler(wrestlers,w_id)
	# Biographical Info
	page = Nokogiri::HTML(open("http://www.profightdb.com/wrestlers/-#{w_id}.html"))
	puts "HEY"
	
	info = page.css('table')[0]
	
	info.to_s =~ /Date (O|o)f Birth\:\<\/strong\>.*\<.*\>(.*)\<\/a\>/
	
	wrestlers[w_id][:dob] = $2
	
	wrestlers[w_id][:nationality] = page.css('table')[0].css('tr')[2].css('td')[0].text[-3..-1]
	
	# Rankings
	page = Nokogiri::HTML(open("http://www.profightdb.com/pwi/-#{w_id}.html"))
	puts "YO"
	
	rankings = page.css('.table-wrapper')[0].css('.gray')
	
	rankings_table = {}
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
		
		rankings_table[year] = {:position => position, :change => change}
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
crawl_wait = 1

14.downto(1) do |page|
    crawl_page(shows,"WWF",page)
    sleep(crawl_wait)
end

21.downto(1) do |page|
    crawl_page(shows,"WWE",page)
    sleep(crawl_wait)
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
		    	sleep(crawl_wait)
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
		    	sleep(crawl_wait)
		    end
		
		
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
			    
		
		update_stats(wrestlers,w_match[:wrestler1_id], w_match[:wrestler2_id], show, w_match)
			    
		}
	}
}
