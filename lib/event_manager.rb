require "csv"
require "sunlight/congress"
require "erb"
require "date"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/\D/, "")
  if phone_number.length < 10 || phone_number.length > 11 ||(phone_number.length == 11 && phone_number[0] != "1")
    phone_number = nil
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number = phone_number[1..-1]
  end
  phone_number
end

def isolate_signup_hour(regdate)
  DateTime.strptime(regdate.to_s, '%m/%d/%y %H:%M').strftime("%H")
end

def isolate_signup_day(regdate)
  DateTime.strptime(regdate.to_s, '%m/%d/%y %H:%M').wday
end

def save_daily_signup_report(daily_signup_report)
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/daily_signup_report.html"
  File.open(filename, 'w') do |file|
    file.puts daily_signup_report
  end
end

def save_hourly_signup_report(hourly_signup_report)
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/hourly_signup_report.html"
  File.open(filename, 'w') do |file|
    file.puts hourly_signup_report
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
daily_signup_template = File.read "daily_signup_report.erb"
hourly_signup_template = File.read "hourly_signup_report.erb"

erb_template = ERB.new template_letter
erb_daily_signup = ERB.new daily_signup_template
erb_hourly_signup = ERB.new hourly_signup_template




signup_hours = Hash.new(0)
signup_days = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  signup_hours[isolate_signup_hour(row[:regdate])] += 1
  signup_days[isolate_signup_day(row[:regdate])] += 1
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letters(id, form_letter)
end

daily_signup_report = erb_daily_signup.result(binding)
save_daily_signup_report(daily_signup_report)

hourly_signup_report = erb_hourly_signup.result(binding)
save_hourly_signup_report(hourly_signup_report)

