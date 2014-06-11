# Process a poll from pollsnack

FN = "processed_poll_data.tsv"

def fmt_obj(o)
	File.open(FN, 'a') {|out_file| 
		out_file.write "#{o["idx"]}\t" 
		(1..9).each do |n|
			out_file.write "#{o[n]}\t" 
		end
		out_file.write("\n")
	}
end
File.delete(FN) if File.exists? FN
content =IO.read("raw_poll.txt")
lines=content.split(/\r?\n/)
o = nil
q_num = nil
i = 0
questions={}

lines.each do |line| 
	line.chomp!
	if /\d\t/.match line# the question text.
		fmt_obj(questions) #if o.nil?
		fmt_obj(o) unless o.nil?
		o={}
		i=i+1
		o["idx"]= i 
		
	else #lines with data data
		match_data_num= /(\d)\./.match line
		if match_data_num
			q_num_s = match_data_num[1]
			q_num = q_num_s.to_i 
			questions[q_num]=line# question obj will be rebuilt many times, but it is not a problem
		else
			if not /^Current/.match line
				raise "num nil" if q_num.nil?
				raise "o nil" if o.nil?
				range_match= /^\d\d?(-)\d\d?$/.match line
				unless range_match.nil?
 					line.gsub!(/-/," to ")
				end
				line= "N/A #{i}" if line=="" 
				o[q_num]=line
			end
		end
	end
end
fmt_obj(o) unless o.nil?


	