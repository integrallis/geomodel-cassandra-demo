require 'csv'
require 'hashie'

index = 0
['sc091aai'
  #, 'sc091akn', 'sc091aow'
  ].each do |file|
  csv_fname = Rails.root.join("db/seeds/sc091a_csv/#{file}.csv")
  File.open(csv_fname).each_line do |raw_line|
    line = CSV.parse_line(raw_line, {col_sep: ","})
    
    # ncessch
    school_id = line[0]
    # schnam09
    name = line[1].gsub("'", "''")
    # mstree09
    address = line[2].gsub("'", "''")  
    # mcity09
    city = line[3].gsub("'", "''")
    # mstate09
    state = line[4]
    # mzip09
    zipcode = line[5]
    # mzip409
    zipcode4 = line[6] || ''
    # member09
    number_of_students= line[7]
    # phone09
    phone = line[8]
    # ulocal09
    urbanicity_code = line[9]
    # type09
    school_type = line[10]
    # level09
    school_level = line[11]
    # gslo09
    low_grade_offered = line[12]
    # gshi09
    high_grade_offered = line[13]
    # status09
    school_status = line[14]
    
    puts "#{index} :: Processing school #{school_id}, #{name}"
    
    if state == 'AZ'
      School.create({
        school_id: school_id,
        name: name,
        address: address,
        city: city,
        state: state,
        zipcode: zipcode,
        zipcode4: zipcode4,
        number_of_students: number_of_students,
        phone: phone,
        urbanicity_code: urbanicity_code,
        school_type: school_type,
        school_level: school_level,
        low_grade_offered: low_grade_offered,
        high_grade_offered: high_grade_offered,
        school_status: school_status
      })
    end
  
    index = index + 1
  end
end