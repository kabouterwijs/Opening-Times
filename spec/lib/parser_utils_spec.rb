require File.dirname(__FILE__) + '/../spec_helper'

include ParserUtils

describe "extract_postcode" do

  it "should return nil if the string doesn't contain a valid postcode" do
    extract_postcode("").should be_nil
    extract_postcode("This is not the string you are looking for").should be_nil
  end

  it "should return the first valid postcode from a string in uppercase" do
    extract_postcode("SE15 5TL").should == "SE15 5TL"
    extract_postcode("se22 8hu").should == "SE22 8HU"
    extract_postcode("SW1a 0Aa").should == "SW1A 0AA"
    extract_postcode("SW1a 0Aa SE14 3LF").should == "SW1A 0AA"
    extract_postcode("SW1a 0Aa moved to SE14 3LF").should == "SW1A 0AA"
    extract_postcode("1 Virginia Street, London, E98 1TT").should == "E98 1TT"
    extract_postcode("<div class=\"addr\">Rawreth Lane<br/>Rayleigh<br/>SS6 9RN<br/><strong>Tel:</strong> 01268 654600</div>").should == "SS6 9RN"
  end

  it "should put a space after the postal district if once isn't already present" do
    extract_postcode("bn271jl").should == "BN27 1JL"
    extract_postcode("bn27 1jl").should == "BN27 1JL"
    extract_postcode("bn27  1jl").should == "BN27 1JL"
    extract_postcode("bn27 \n \t 1jl").should == "BN27 1JL"
  end

  it "should replace o with 0 where appropriate" do
    extract_postcode("RG2 ODD").should == "RG2 0DD"
  end
  
  it "should not replace o with 0 where it doesn't need to" do
    extract_postcode("PO15 5UB").should == "PO15 5UB"  
  end

  it "should accept the following postcodes" do
    # postcodes I've had problems with in the past
    extract_postcode("E1W 1YY").should == "E1W 1YY"
    extract_postcode("EC3 9AU").should == "EC3 9AU"
    extract_postcode("SR7 7HN").should == "SR7 7HN"
    extract_postcode("B93 0LE").should == "B93 0LE"
     
#    extract_postcode("").should == ""
  end

end

describe "extract_address" do

  it "should return the address and postcode" do
    address, postcode = extract_address("1 Virginia Street, London, E98 1TT")
    address.should == "1 Virginia Street, London"
    postcode.should == "E98 1TT"
  end

  it "should return the address and postcode, removing HTML" do
    address, postcode = extract_address("<div class=\"addr\">Rawreth Lane<br/>Rayleigh<br/>SS6 9RN<br/><strong>Tel:</strong> 01268 654600</div>")
    address.should == "Rawreth Lane, Rayleigh"
    postcode.should == "SS6 9RN"
  end

  it "should return the address and postcode, from test case ADSA" do
    address, postcode = extract_address("<div class=\"addr\">\nRooley Lane<br/>\nBradford<br/>\nBD4 7SR<br/>\n<strong>Tel:</strong> 01274 474000\n</div>\n")
    address.should == "Rooley Lane, Bradford"
    postcode.should == "BD4 7SR"
  end

end


describe "extract_phone" do

  it "should return an array of valid telephone numbers" do
    one, two = extract_phone("Tel: (020) 7500 3400 or fax: (020) 7500 3401")
    one.should == "(020) 7500 3400"
    two.should == "(020) 7500 3401"

    one, two = extract_phone("Tel: 01892 750 340 or fax: (0845) 760 60 60")
    one.should == "(01892) 750340"
    two.should == "(0845) 760 6060"
  end

  it "should return number in the correct format" do
    one, two = extract_phone("Tel: 02075003400 or fax: 0207 500 3401")
    one.should == "(020) 7500 3400"
    two.should == "(020) 7500 3401"

    one, two = extract_phone("Tel: 01892 750340 or fax: 0845 760 60 60")
    one.should == "(01892) 750340"
    two.should == "(0845) 760 6060"

    one, two = extract_phone("Tel: 020-7500-3400 or fax: (0207) 500 3401")
    one.should == "(020) 7500 3400"
    two.should == "(020) 7500 3401"
  end

  it "should return the correct geographic format" do
    extract_phone("02077327732").should == "(020) 7732 7732" # 020 London
    extract_phone("02087327732").should == "(020) 8732 7732" # 020 London
    extract_phone("02037327732").should == "(020) 3732 7732" # 020 London

    extract_phone("02380327732").should == "(023) 8032 7732" # 023 Southampton and Portsmouth
    extract_phone("02476327732").should == "(024) 7632 7732" # 024 Coventry
    extract_phone("02890327732").should == "(028) 9032 7732" # 028 Northern Ireland
    extract_phone("02920327732").should == "(029) 2032 7732" # 029 Cardiff

    extract_phone("01132773277").should == "(0113) 277 3277" # 0113 Leeds
    extract_phone("01143773277").should == "(0114) 277 3277" # 0114 Sheffield
    extract_phone("01158773277").should == "(0115) 977 3277" # 0115 Nottingham
    extract_phone("01162773277").should == "(0116) 277 3277" # 0116 Leicester
    extract_phone("01179773277").should == "(0117) 977 3277" # 0117 Bristol
    extract_phone("01189773277").should == "(0118) 977 3277" # 0118 Reading

    extract_phone("01212773277").should == "(0121) 277 3277" # 0121 Birmingham
    extract_phone("01312773277").should == "(0131) 277 3277" # 0131 Edinburgh
    extract_phone("01412773277").should == "(0141) 277 3277" # 0141 Glasgow
    extract_phone("01512773277").should == "(0151) 277 3277" # 0151 Liverpool
    extract_phone("01612773277").should == "(0161) 277 3277" # 0161 Manchester
    extract_phone("01912773277").should == "(0191) 277 3277" # 0191 Tyne and Wear and Durham

    extract_phone("013873 32777").should == "(013873) 32777" # 013873 Langholm
    extract_phone("015242 32777").should == "(015242) 32777" # 015242 Hornby-with-Farleton
    extract_phone("015394 32777").should == "(015394) 32777" # 015394 Hawkshead
    extract_phone("015395 32777").should == "(015395) 32777" # 015395 Grange-over-Sands
    extract_phone("015396 32777").should == "(015396) 32777" # 015396 Sedbergh
    extract_phone("016973 32777").should == "(016973) 32777" # 016973 Wigton
    extract_phone("016974 32777").should == "(016974) 32777" # 016974 Raughton Head
    extract_phone("016977 2333").should  == "(016977) 2333"  # 016977 Brampton (4-fig.)
    extract_phone("016977 45777").should == "(016977) 45777" # 016977 Brampton
    extract_phone("017683 32777").should == "(017683) 32777" # 017683 Appleby-in-Westmorland
    extract_phone("017684 32777").should == "(017684) 32777" # 017684 Pooley Bridge
    extract_phone("017687 32777").should == "(017687) 32777" # 017687 Keswick
    extract_phone("019467 32777").should == "(019467) 32777" # 019467 Gosforth
  end

  it "should return the phone, from test case ADSA" do
    extract_phone("<div class=\"addr\">\nRooley Lane<br/>\nBradford<br/>\nBD4 7SR<br/>\n<strong>Tel:</strong> 01274 474000\n</div>\n").should == "(01274) 474000"
  end

  it "should return the phone from test case Farmfoods" do
  	extract_phone('<meta name="Telephone" content="+44 (0) 1236 456789" />').should == "(01236) 456789"
  end

  it "should return the phone from test case Sainsbury's" do
  	extract_phone('<p>612  -  614 Finchley Road<br />GOLDERS GREEN<br />London<br />NW11 7RX<br /><abbr title="Telephone">Tel</abbr>: 020 8458 6977<br /></p>').should == "(020) 8458 6977"
  end
end

describe "br_to_comma" do
  it "should turn html <br> <br/> and <br /> tags in to commas" do
    br_to_comma("Apple<br>banana<br/>pear<br />and grape").should == "Apple, banana, pear, and grape"
  end
end

describe "add_colon" do
  it "should add a colon within a time string" do
    add_colon("900").should == "9:00"
    add_colon("0900").should == "09:00"
    add_colon("1900").should == "19:00"
    add_colon("9.00").should == "9:00"
    add_colon("19.00").should == "19:00"
    add_colon("9:00").should == "9:00"
    add_colon("19:00").should == "19:00"
  end
end

describe "ParserUtils.extract_lat_lng" do
  it "should extract a latitude and longitude from a string" do
    ParserUtils.extract_lat_lng("51.1 0.4").should == ["51.1", "0.4"]
    ParserUtils.extract_lat_lng("51.1,0.4").should == ["51.1", "0.4"]
    ParserUtils.extract_lat_lng(" 51.1, 0.4 ").should == ["51.1", "0.4"]
    ParserUtils.extract_lat_lng(" 51.1 ,0.4 ").should == ["51.1", "0.4"]
    ParserUtils.extract_lat_lng(" 51.1 , 0.4 ").should == ["51.1", "0.4"]
    ParserUtils.extract_lat_lng("-51.1,0.4").should == ["-51.1", "0.4"]
    ParserUtils.extract_lat_lng("51.1,-0.4").should == ["51.1", "-0.4"]
    ParserUtils.extract_lat_lng("51").should == nil
    ParserUtils.extract_lat_lng("woo").should == nil
    ParserUtils.extract_lat_lng("East Dulwich").should == nil
  end
end
