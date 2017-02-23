require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'

def csv_entry(w1s,w2s,w1_h2h,w2_h2h,show,w_match,pwi_year,num)
	champ_match = 0
	current_champ = 0
	normal_match = 0
	age_dif = (w2s[:dob].to_time - w1s[:dob].to_time)/(60*60*24*365)
	winner = if w_match[:winner] then 1 else 0 end

	if num == 2 then 
		winner = winner * -1 
	end
			    
	if !w_match[:title].strip.empty? then
		champ_match = 1
	end
			    
	case w_match[:current_champ]
	when "None"
		current_champ = 0
	when "Wrestler #{num}"
		current_champ = 1
	when "Wrestler #{num}"
		current_champ = -1
	end
			    
	case w_match[:type].strip
	when /ark/
		normal_match = -1
	when ""
		normal_match = 0
	else
		normal_match = 1
	end
			    
			
	[
	champ_match,
	current_champ,
	w_match[:order].to_i,
	normal_match,
	show[:date].to_time.month,
	show[:date].to_time.year,
	age_dif,
	stat_diff(w1s,w2s,:ppv_matches),
	stat_diff(w1s,w2s,:ppv_wins),
	perc_stat_diff(w1s,w2s,:ppv_wins,:ppv_matches,0.5),
	stat_diff(w1s,w2s,:ppv_dq_wins),
	perc_stat_diff(w1s,w2s,:ppv_dq_wins,:ppv_wins,0),
	stat_diff(w1s,w2s,:ppv_pin_wins),
	perc_stat_diff(w1s,w2s,:ppv_pin_wins,:ppv_wins,0),
	stat_diff(w1s,w2s,:ppv_sub_wins),
	perc_stat_diff(w1s,w2s,:ppv_sub_wins,:ppv_wins,0),
	stat_diff(w1s,w2s,:ppv_losses),
	stat_diff(w1s,w2s,:ppv_dq_losses),
	perc_stat_diff(w1s,w2s,:ppv_dq_losses,:ppv_wins,0),
	stat_diff(w1s,w2s,:ppv_pin_losses),
	perc_stat_diff(w1s,w2s,:ppv_pin_losses,:ppv_wins,0),
	stat_diff(w1s,w2s,:ppv_sub_losses),
	perc_stat_diff(w1s,w2s,:ppv_sub_losses,:ppv_wins,0),
	stat_diff(w1s,w2s,:ppv_draws),
	stat_diff(w1s,w2s,:ppv_streak),
	stat_diff(w1s,w2s,:ppv_championship_wins),
	stat_diff(w1s,w2s,:ppv_championship_losses),
	stat_diff(w1s,w2s,:ppv_championship_defense_wins),
	stat_diff(w1s,w2s,:ppv_championship_defense_losses),
	stat_diff(w1s,w2s,:ppv_championship_challenge_wins),
	stat_diff(w1s,w2s,:ppv_championship_challenge_losses),
	w1s[:ppv_last_match].to_time - w2s[:ppv_last_match].to_time,
	stat_diff(w1_h2h,w2_h2h,:ppv_matches),
	stat_diff(w1_h2h,w2_h2h,:ppv_wins),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_wins,:ppv_matches,0.5),
	stat_diff(w1_h2h,w2_h2h,:ppv_dq_wins),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_dq_wins,:ppv_wins,0),
	stat_diff(w1_h2h,w2_h2h,:ppv_pin_wins),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_pin_wins,:ppv_wins,0),
	stat_diff(w1_h2h,w2_h2h,:ppv_sub_wins),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_sub_wins,:ppv_wins,0),
	stat_diff(w1_h2h,w2_h2h,:ppv_losses),
	stat_diff(w1_h2h,w2_h2h,:ppv_dq_losses),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_dq_losses,:ppv_wins,0),
	stat_diff(w1_h2h,w2_h2h,:ppv_pin_losses),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_pin_losses,:ppv_wins,0),
	stat_diff(w1_h2h,w2_h2h,:ppv_sub_losses),
	perc_stat_diff(w1_h2h,w2_h2h,:ppv_sub_losses,:ppv_wins,0),
	stat_diff(w1_h2h,w2_h2h,:ppv_draws),
	stat_diff(w1_h2h,w2_h2h,:ppv_streak),
	stat_diff(w1_h2h,w2_h2h,:ppv_championship_wins),
	stat_diff(w1_h2h,w2_h2h,:ppv_championship_losses),
	stat_diff(w1_h2h,w2_h2h,:ppv_championship_defense_wins),
	stat_diff(w1_h2h,w2_h2h,:ppv_championship_defense_losses),
	stat_diff(w1_h2h,w2_h2h,:ppv_championship_challenge_wins),
	stat_diff(w1_h2h,w2_h2h,:ppv_championship_challenge_losses),
	w1_h2h[:ppv_last_match].to_time - w2_h2h[:ppv_last_match].to_time,
	w1s[:pwi_rankings][pwi_year][:position] - w2s[:pwi_rankings][pwi_year][:position],
	w1s[:pwi_rankings][pwi_year][:change] - w2s[:pwi_rankings][pwi_year][:change],
	winner
	]
end

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

def stat_diff(w1s,w2s,stat)
	puts stat.to_s
	w1s[stat] - w2s[stat]
end

def perc_stat_diff(w1s,w2s,stat_nom,stat_denom,default)
	perc_stat(w1s,stat_nom,stat_denom,default) - perc_stat(w2s,stat_nom,stat_denom,default)
end

def each_stat(wrestler,stat)
	wrestler.each do |w|
		w[stat] = yield w[stat]
	end
end

def perc_stat(ws,stat_nom,stat_denom,default)
	if ws[stat_denom] == 0 then
		# MOST LIKELY ARBITRARY
		default
	else
		ws[stat_nom].to_f/ws[stat_denom].to_f
	end
end

def update_stats(wrestlers,w1,w2,show,w_match)
    wrestler1_stats = wrestlers[w1]
    wrestler2_stats = wrestlers[w2]
    
    if wrestler1_stats[:h2h][w2][:ppv_last_match] == 0 then
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
@crawl_wait = 1
testing = false

14.downto(1) do |page|
    crawl_page(shows,"WWF",page)
    sleep(@crawl_wait)
end

21.downto(1) do |page|
    crawl_page(shows,"WWE",page)
    sleep(@crawl_wait)
end


if (testing) 
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
		        "W1 PPV Matches",
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
		        "W1 H2H PPV Matches",
		        "W1 H2H PPV Wins",
		        "W1 H2H PPV DQ Wins",
		        "W1 H2H PPV Pin Wins",
		        "W1 H2H PPV Sub Wins",
		        "W1 H2H PPV Losses",
		        "W1 H2H PPV DQ Losses",
		        "W1 H2H PPV Pin Losses",
		        "W1 H2H PPV Sub Losses",
		        "W1 H2H PPV Draws",
		        "W1 H2H PPV Streak",
		        "W1 H2H PPV Championship Wins",
		        "W1 H2H PPV Championship Losses",
		        "W1 H2H PPV Championship Defense Wins",
		        "W1 H2H PPV Championship Defense Losses",
		        "W1 H2H PPV Championship Challenge Wins",
		        "W1 H2H PPV Championship Challenge Losses",
		        "W1 H2H Last PPV Match",
		        "W1 PWI Ranking",
		        "W1 PWI Change",
		        "W2 Age",
		        "W2 PPV Matches",
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
		        "W2 PPV Matches",
		        "W2 H2H PPV Wins",
		        "W2 H2H PPV DQ Wins",
		        "W2 H2H PPV Pin Wins",
		        "W2 H2H PPV Sub Wins",
		        "W2 H2H PPV Losses",
		        "W2 H2H PPV DQ Losses",
		        "W2 H2H PPV Pin Losses",
		        "W2 H2H PPV Sub Losses",
		        "W2 H2H PPV Draws",
		        "W2 H2H PPV Streak",
		        "W2 H2H PPV Championship Wins",
		        "W2 H2H PPV Championship Losses",
		        "W2 H2H PPV Championship Defense Wins",
		        "W2 H2H PPV Championship Defense Losses",
		        "W2 H2H PPV Championship Challenge Wins",
		        "W2 H2H PPV Championship Challenge Losses",
		        "W2 H2H Last PPV Match",
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
			                                            :h2h=>Hash.new({
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
				                                            :ppv_last_match => 0
			                                            	})
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
			                                            :h2h=>Hash.new({
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
				                                            :ppv_last_match => 0
			                                            	})
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
				    wrestlers[w_match[:wrestler1_id]][:ppv_matches],
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
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_matches],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_dq_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_pin_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_sub_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_dq_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_pin_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_sub_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_draws],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_streak],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_championship_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_championship_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_championship_defense_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_championship_defense_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_championship_challenge_wins],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_championship_challenge_losses],
				    wrestlers[w_match[:wrestler1_id]][:h2h][:wrestler2_id][:ppv_last_match],
				    wrestlers[w_match[:wrestler1_id]][:pwi_rankings][pwi_year][:position],
				    wrestlers[w_match[:wrestler1_id]][:pwi_rankings][pwi_year][:change],
				    (show[:date].to_time - wrestlers[w_match[:wrestler2_id]][:dob].to_time)/(60*60*24*365),
				    wrestlers[w_match[:wrestler2_id]][:ppv_matches],
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
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_matches],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_dq_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_pin_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_sub_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_dq_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_pin_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_sub_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_draws],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_streak],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_championship_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_championship_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_championship_defense_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_championship_defense_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_championship_challenge_wins],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_championship_challenge_losses],
				    wrestlers[w_match[:wrestler2_id]][:h2h][:wrestler1_id][:ppv_last_match],
				    wrestlers[w_match[:wrestler2_id]][:pwi_rankings][pwi_year][:position],
				    wrestlers[w_match[:wrestler2_id]][:pwi_rankings][pwi_year][:change]
				    ]
				    
			
			update_stats(wrestlers,w_match[:wrestler1_id], w_match[:wrestler2_id], show, w_match)
				    
			}
		}
	}
else
	CSV.open("ppv_data_learning.csv","wb") {|csv|
		csv << [
		        "Championship Match?",
		        "Champion? (-1 if W2, 0 if neither, 1 if W1)",
		        "Card Order",
		        "Normal Match Type?",
		        "Month",
		        "Year",
		        "W1-W2 Age",
		        "W1-W2 PPV Matches",
		        "W1-W2 PPV Wins",
		        "W1-W2 PPV Wins %",
		        "W1-W2 PPV DQ Wins",
		        "W1-W2 PPV DQ % of Wins",
		        "W1-W2 PPV Pin Wins",
		        "W1-W2 PPV Pin % of Wins",
		        "W1-W2 PPV Sub Wins",
		        "W1-W2 PPV Sub % of Wins",
		        "W1-W2 PPV Losses",
		        "W1-W2 PPV DQ Losses",
		        "W1-W2 PPV DQ % of Losses",
		        "W1-W2 PPV Pin Losses",
		        "W1-W2 PPV Pin % of Losses",
		        "W1-W2 PPV Sub Losses",
		        "W1-W2 PPV Sub % of Losses",
		        "W1-W2 PPV Draws",
		        "W1-W2 PPV Streak",
		        "W1-W2 PPV Championship Wins",
		        "W1-W2 PPV Championship Losses",
		        "W1-W2 PPV Championship Defense Wins",
		        "W1-W2 PPV Championship Defense Losses",
		        "W1-W2 PPV Championship Challenge Wins",
		        "W1-W2 PPV Championship Challenge Losses",
		        "W1-W2 Last PPV Match",
		        "W1-W2 H2H PPV Matches",
		        "W1-W2 H2H PPV Wins",
		        "W1-W2 H2H PPV Wins %",
		        "W1-W2 H2H PPV DQ Wins",
		        "W1-W2 H2H PPV DQ % of Wins",
		        "W1-W2 H2H PPV Pin Wins",
		        "W1-W2 H2H PPV Pin % of Wins",
		        "W1-W2 H2H PPV Sub Wins",
		        "W1-W2 H2H PPV Sub % of Wins",
		        "W1-W2 H2H PPV Losses",
		        "W1-W2 H2H PPV DQ Losses",
		        "W1-W2 H2H PPV DQ % of Losses",
		        "W1-W2 H2H PPV Pin Losses",
		        "W1-W2 H2H PPV Pin % of Losses",
		        "W1-W2 H2H PPV Sub Losses",
		        "W1-W2 H2H PPV Sub % of Losses",
		        "W1-W2 H2H PPV Draws",
		        "W1-W2 H2H PPV Streak",
		        "W1-W2 H2H PPV Championship Wins",
		        "W1-W2 H2H PPV Championship Losses",
		        "W1-W2 H2H PPV Championship Defense Wins",
		        "W1-W2 H2H PPV Championship Defense Losses",
		        "W1-W2 H2H PPV Championship Challenge Wins",
		        "W1-W2 H2H PPV Championship Challenge Losses",
		        "W1-W2 H2H Last PPV Match",
		        "W1-W2 PWI Ranking",
		        "W1-W2 PWI Change",
		        # Consider adding individual stats here
		        "W1 Winner?"
		        ]
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
			                                            :ppv_last_match => Date.new(1970), # ARBITRARY
			                                            :main_event_appearances=>0,
			                                            :h2h=>Hash.new({
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
				                                            :ppv_last_match => Date.new(1970), # ARBITRARY
			                                            	})
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
			                                            :ppv_last_match => Date.new(1970), # ARBITRARY
			                                            :main_event_appearances=>0,
			                                            :h2h=>Hash.new({
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
				                                            :ppv_last_match => Date.new(1970), # ARBITRARY
			                                            	})
			                                            }
			    	init_wrestler(wrestlers,w_match[:wrestler2_id])
			    end
			    
			    
			    w1s = wrestlers[w_match[:wrestler1_id]]
			    w2s = wrestlers[w_match[:wrestler2_id]]
			    
			    w1_h2h = w1s[:h2h][wrestlers[w_match[:wrestler2_id]]]
			    w2_h2h = w2s[:h2h][wrestlers[w_match[:wrestler1_id]]]
			    
			    
			    csv << csv_entry(w1s,w2s,w1_h2h,w2_h2h,show,w_match,pwi_year,1)
			    csv << csv_entry(w2s,w1s,w2_h2h,w1_h2h,show,w_match,pwi_year,2)
			    
				    
				
				    
			
				update_stats(wrestlers,w_match[:wrestler1_id], w_match[:wrestler2_id], show, w_match)
				    
			}
		}
	}
end