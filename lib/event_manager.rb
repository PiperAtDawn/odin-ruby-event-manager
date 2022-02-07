require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(phone)
  phone = phone.to_s.delete('^0-9')
  length = phone.length
  bad = 'No valid number given'
  return phone if length == 10
  return phone.delete[0] if length == 11 && phone[0] == 1
  bad
end

def registration_times(attendees)
  times = []
  attendees.each do |row|
    begin
      times << Time.strptime(row[:regdate], '%m/%d/%y %k:%M')
    rescue
      next
    end
  end
  times
end

def peak_hours(times)
  hours = times.map { |time| time.strftime('%H').to_i }
  best_hours = (hours.tally.sort_by { |time, occurences| occurences }).reverse
  puts "The best hours are: #{best_hours[0][0]}:00, #{best_hours[1][0]}:00, #{best_hours[2][0]}:00"
end

def peak_days(times)
  days = times.map { |time| Date::DAYNAMES[time.wday] }
  best_days = (days.tally.sort_by { |day, occurences| occurences}).reverse
  puts "The best days are: #{best_days[0][0]}, #{best_days[1][0]}, #{best_days[2][0]}"
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') { |file| file.puts form_letter}
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

times = registration_times(contents)
peak_hours(times)
peak_days(times)

 contents.each do |row|
   id = row[0]
   name = row[:first_name]
   phone = clean_phone_number(row[:homephone])

   zipcode = clean_zipcode(row[:zipcode])

   legislators = legislators_by_zipcode(zipcode)

   form_letter = erb_template.result(binding)

   save_thank_you_letter(id, form_letter)
 end
