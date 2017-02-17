require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'

def initial_query(page,ppv)
    if ppv then
        ppv = "yes"
    else
        ppv = "no"
    end
    "http://www.profightdb.com/cards/wwe-cards-pg#{page}-#{ppv}-2.html?order=&type="
end

shows = []

21.downto(1) do |page|
    page = Nokogiri::HTML(open(initial_query(page,true)))
    
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


CSV.open("ppv_data.csv","wb") {|csv|
	csv << ["wrestler 1","wrestler 1 id","wrestler 2","wrestler 2 id","current champion","winner","match ending","card order","title","match type","date","show name","location"]
	shows.each { |show|
		show[:matches].each { |w_match|
			csv << [
			    w_match[:wrestler1],w_match[:wrestler1_id],w_match[:wrestler2],w_match[:wrestler2_id],w_match[:current_champ],w_match[:winner].to_s,
			    w_match[:ending],w_match[:order],w_match[:title],w_match[:type],
			    show[:date],show[:name],show[:location]
			    ]
		}
	}
}
