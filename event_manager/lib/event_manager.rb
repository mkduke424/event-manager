require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new

  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
   civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']).officials
  
  
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exist? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename,"w") do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone)
  phone = phone.tr('^0-9', '')
  if phone.length < 10
     " #{phone} Invalid Number"
   elsif phone.length == 10
      phone
   elsif phone.length == 11
     if phone[0] == "1"
       phone[1..10]
     else
       "#{phone} Invalid Number"
     end
   elsif phone.length > 11
      "#{phone} Invalid Number"
  end
end

# returns the hour in a 24 hour time period that has the most registrations(Only the first instance of the highest hour) 
def hour_with_most_traffic(arr_hours)
  analyze_hour = arr_hours.tally
  hottest_hour = analyze_hour.key(analyze_hour.values.max)
  "The hour with the most traffic is: #{hottest_hour} on a 24 hour clock"
end
# returns the day of the week that users registered the most
def day_with_most_traffic(arr_days)
  analyze_days = arr_days.tally
  hottest_day = analyze_days.key(analyze_days.values.max)
  days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  "The day with the most traffic is: #{days[hottest_day]}"
end

puts "EventManager Initialized"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read"form_letter.erb"
erb_template = ERB.new template_letter
hours_to_analyze = []
days_to_analyze = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = row[:homephone]
  time = row[:regdate]
  
  time = DateTime.strptime(time, '%m/%d/%Y %H:%M')
  hours_to_analyze.push(time.hour)
  days_to_analyze.push(time.wday)
  
  phone = clean_phone_numbers(phone)

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)
  
 

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

end

puts hour_with_most_traffic(hours_to_analyze)
puts day_with_most_traffic(days_to_analyze)
