namespace :markus do
  namespace :benchmark do
  
  desc "Loads 'num=X' number of students into the DB. Destroys existing students."
  task(:students_create => :environment) do
    num = ENV['num']
    if num.nil?
      $stderr.puts("Usage: rake markus:benchmark:students_create num=...")
    end
    num = num.to_i
    print("Destroying all existing students ...")
    Student.all.each do |student|
      if !student.destroy
        $stderr.print "Error destroying record #{student.user_name}:"
        student.errors.each do |error_message|
          $stderr.puts error_message[0] + ' ' + error_message[1]
        end
      end
    end
    puts(" done.\n")
    print("Creating #{num} student(s) of the form student_# ...")
    (1..num).each do |num|
      student = Student.new({:user_name => "student_#{num}",
                             :first_name => "Bob #{num}",
                             :last_name => "Blaster #{num}"})
      if !student.save
        $stderr.print "Error saving record:"
        student.errors.each do |error_message|
          $stderr.puts error_message[0] + ' ' + error_message[1]
        end
      end
    end
    puts(" **** DONE! **** ")
  end

  end
end
