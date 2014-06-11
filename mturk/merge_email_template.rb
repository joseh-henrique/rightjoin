require 'csv'

DIR = "C:\\temp\\"

def main
 
  input_1 = "#{DIR}template.txt" 
  input_2 ="#{DIR}ambassadors.csv"  
  file1  = File.new(input_1)
  file2  = File.new(input_2)
  template_txt   = File.read(file1)
  aa_csv   = CSV.read(file2)
  hdr = aa_csv.shift
  expect=%w(Name, Email, Article)
  hdr=hdr[0...3]
  #raise "#{hdr} should be #{expect}" unless hdr==expect
  aa_csv.each{ |arr|
    # name, email, article
    email = template_txt.sub("{{field_Name}}", arr[0]).sub("{{field_Article}}",arr[2])
    email = arr[1] + "\r\n\r\n" + email
    
    output_name = "#{DIR}#{arr[1]}.txt"

    File.open(output_name, 'w') {|f| f.write(email) }
  }
  puts "done"
end

main()
