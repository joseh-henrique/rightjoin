module UserCommon
  extend ActiveSupport::Concern
  
  included do 
    attr_accessible  :first_name, :last_name, :email, :password, :password_confirmation
    # Also: attribute :sample, default false
  
    has_secure_password
    
    before_validation :before_user_validation
    before_save :create_remember_token
    validates :password, :length => { :minimum => 6 }, :if => Proc.new { |user| !user.password.blank? || user.new_record? }
    validates :status, :presence => true, :numericality => {:greater_than_or_equal_to  => UserConstants::PENDING, :less_than_or_equal_to => UserConstants::DEACTIVATED}
    validates :email, :presence=> true, :format=> { :with=> Constants::VALID_EMAIL_REGEX }, :length => { :maximum => 255 },
                      :uniqueness=> { :case_sensitive=> false , :message=> " already in use. Please sign in or use \u201CForgot Password\u201D <a href='#email-input'>above</a>." },
                      :if => Proc.new { |user| !user.email.blank? || user.new_record? }
  
    # If you give sample@rightjoin.co.il as your email, this code will generate an email address like sample+777@rightjoin.co.il ,
    # incrementing to provide a unique number. However, user and employer instances are incremented separately, so that the same
    # address may end up being used for instances of both. This is OK.   
    def before_user_validation
      if self.new_record?
       self.email = self.email.downcase.strip
       Constants::SAMPLE_USER_EMAIL_TEMPLATES.each do |sample_user_email_template| 
           if self.email == sample_user_email_template  % ""
             self.sample = true
             self.email = sample_user_email_template  % "+#{self.class.count}"
             self.password = UserConstants::SAMPLE_PASSWORD
             self.status = UserConstants::VERIFIED
             break
           end
        end
      end
    end
  
    def verify
       update_attribute(:status, UserConstants::VERIFIED) unless verified?
    end
    
    def deactivate
     update_attribute(:status, UserConstants::DEACTIVATED) unless deleted?
    end
    
    def pending?
      self.status.nil? or status == UserConstants::PENDING 
    end
  
    def verified?
      self.status == UserConstants::VERIFIED
    end
    
    def deleted?
      self.status == UserConstants::DEACTIVATED 
    end
    
    def employee?
      self.instance_of? User
    end
    
    def employer?
      self.instance_of? Employer
    end
    
    def reference_num(scramble = false)
      Utils.reference_num(self, scramble)
    end
    
    def validate_email_field!
      if self._validators[:email]
        self.errors.clear
        self._validators[:email].each { |v| v.validate self }
        raise ActiveRecord::RecordInvalid.new(self) unless self.errors.empty?
      end
    end
  
   def random_pw()
      adjectives=  %w(adorable beautiful clean able elegant fancy glamorous handsome long magnificent plain quaint sparkling 
          red orange yellow green blue purple gray black white mauve scarlet crimson golden silvery alive better careful clever  easy famous gifted helpful important 
          inexpensive mushy odd even powerful rich shy tender vast bewildered fierce itchy pretty edgy tremendous ambitious flourishing
          mysterious agreeable brave calm delightful wonderful eager faithful gentle ginormous tweensie smiley garumptious
          cheery happy giggling laughing joyous joyful ecstatic pleased tranquil mesmerized efficient flying soaring flying confident articulate  
          jolly kind lively nice obedient proud relieved silly thankful victorious witty zealous broad curved deep spectacular 
          flat high hollow low narrow round shallow skinny thin square steep straight  big colossal giant gigantic great huge 
          immense large little mammoth massive miniature petite lovely short small tall teeny tiny cooing deafening faint 
          hissing loud melodic noisy purring quiet raspy  thundering voiceless whispering ancient brief early fast late 
          long modern old quick rapid short slow swift young delicious fresh  juicy hot icy loose melted nutritious 
          rainy salty sticky strong sweet tart uneven  wet wooden yummy boiling breezy broken bumpy 
          chilly cold cool crooked cuddly curly damp strange dry  flaky fluffy freezing hot warm wet abundant 
          empty full heavy light fuzzy many numerous sparse)
      
      adjarray=    
        [adjectives, adjectives].map{|arr| arr.sample.downcase.gsub(/[^a-zA-Z]/, '').capitalize  }
         
      nouns=  %w(ball bat bed book boy bun broom can cake cap car cat cow cub cup dad day dog doll dust fan ape 
           monkey key wine beer whiskey rum gin tonic martini monk gorilla lemur ant artichoke
           feet girl gun hall hat hen hippo jar kite man map men mom pan pet pie pig pot rat son sun toe tub van apple cheese yogurt yurt igloo arm banana bike chimp automobile
           bird book chin clam class clover club corn crayon crow crown crowd crib desk dime dirt dress  field flag flower aardvark
           fog game heat hill home horn hose joke juice kite lake pond maid mask mice milk mint meal meat moon planet mother morning name nest 
           nose pear pen pencil plant rain river creek rivulet stream spring road rock room rose seed shape shoe shop show sink snail snow soda sofa jalopy
           meteor asteroid star step stew stove straw string summer swing table team tent test toes tree vest water wing winter woman  
           alarm animal aunt bait balloon bath bead beam bean bedroom boot bread brick brother camp chicken children crook deer 
           dock doctor downtown drum dust eye family father food frog goose grade grandfather grandmother grape grass
           hook horse jail jam kiss kitten light loaf lock lunch lunchroom meal mother notebook owl pail parent park plot rabbit hare bunny
           rake robin sack sail scale sister soap song spark space spoon spot spy summer tiger toad town trail tramp tray 
           trick trip uncle vase winter water week wheel wish wool yard zebra actor airplane airport army baseball beef birthday 
           boy brush bushes butter cast cave cent cherry olive vine cobweb coil cracker dinner eggnog elbow face fireman  
           gate glove glue goldfish fish goose grain hair haircut hobbies holiday hot jellyfish ladybug mailbox number oatmeal pail laugh giggle
           pancake pear pest popcorn queen dune  forest sea quicksand sand quiet quilt rainstorm scarecrow scarf stream street sugar throne toothpaste canyon
           twig volleyball wood wrench advice answer apple plum arithmetic badge basket basketball battle beast beetle beggar bee scarab
           brain branch bubble bucket cactus cannon cattle celery cellar cloth coach coast crate cream daughter donkey  
           earthquake feast fifth finger flock frame furniture geese ghost giraffe governor honey hope hydrant icicle income
           island jeans judge lace lamp lamp lettuce lion marble month north ocean patch plane playground riddle rifle scale scarab
           seashore sheet sidewalk skate  sleet smile grin chuckle smoke stage station thrill throat throne title toothbrush turkey underwear
           vacation vegetable visitor voyage year achievement rhyme verse mark note action activity aftermath afternoon afterthought thought apparel 
           appliance beginner believe slate stone pebble border margin breakfast cabbage cable calculator calendar caption carpenter cemetery 
           channel circle creator creature education faucet feather friction fruit fuel galley guide guitar health heart idea kitten 
           laborer language lawyer linen locket lumber magic minister mitten money mop mountain music partner passenger pickle picture 
           plantation plastic pleasure pocket  railway recess reward route scene scent squirrel stranger suit sponge
           sweater temper territory texture thread treatment veil vein volcano wealth weather wilderness wren wrist writer valley dale
           shoulder arm leg finger ear peach apricot melon kumquat lemon anthropology history impala antelope cheetah ibex goat)
      
      noun = nouns.sample.downcase.gsub(/[^a-zA-Z]/, '').capitalize.pluralize
      num = rand(97)+2 # from 2  (for plural) through 99 (no more than 2 digits)   
      pw = num.to_s+adjarray[0]+adjarray[1]+noun

      pw
  end    
  
    private
  
    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64 if self.remember_token.nil?
    end
  end
end
