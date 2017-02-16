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


21.downto(1) do |page|
    page = Nokogiri::HTML(open(initial_query(page,true)))
    page.css('.table-wrapper')[0].css('table')[0].css('tr').reverse[0..(-2)].each { |row| 
        date, company, show_name, location = row.css('td').map { |col|
            col.css('a')[0].text
        }
        puts company.inspect
        puts date.inspect
        puts show_name.inspect
        puts location.inspect
        puts
    }
end
