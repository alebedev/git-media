require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# I realize this is horrible, horrible rspec but I want to run the actual
# git commands and it takes forever to setup the test env each time, so
# i'm squeezing a bunch of tests into each 'it' - don't judge me

describe "Media" do
    
  it "should clean and smudge and save data in buffer area" do
    in_temp_git_w_media do
      git('add .')
      git("commit -m 'testing'")
      
      # check that we saved the sha and not the data
      size = git("cat-file -s master:testing1.mov")
      size.should eql('41')
      
      # check that the data is in our buffer area
      Dir.chdir('.git/media/objects') do
        objects = Dir.glob('*')
        objects.should include('20eabe5d64b0e216796e834f52d61fd0b70332fc')
      end
      
      # check that removing the file and checking out returns the data
      File.unlink('testing1.mov')
      git('checkout testing1.mov')
      File.size('testing1.mov').should eql(7)
      
      # check that removing the file and checking out sans data returns the sha
      File.unlink('testing1.mov')
      File.unlink('.git/media/objects/20eabe5d64b0e216796e834f52d61fd0b70332fc')
      git('checkout testing1.mov')
      File.size('testing1.mov').should eql(41)
    end
  end
  
  it "should show me the status of my directory"
  
  it "should sync with a local transport"
  
end
