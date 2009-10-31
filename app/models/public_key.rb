class PublicKey < ActiveRecord::Base

  has_many :repositories, :through => :permissions
  has_many :permissions, :dependent => :destroy

  validates_format_of :email, :with => %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i
  validates_presence_of :description
  validates_presence_of :source
  validates_format_of :source, :with => %r{^(-+\s?BEGIN \w*\s*PUBLIC|ssh-rsa )}i, :allow_blank => true, :allow_nil => true # accept keys beginning with 'ssh-rsa' or something like 'BEGIN PUBLIC KEY' 
  validates_uniqueness_of :source

  after_save :persist_publickey, :add_to_git
  after_destroy :delete_publickey, :remove_from_git

  def keyfile
    File.join(configatron.gitosis_admin_root, configatron.gitosis_keydir, self.keyfilename)
  end

  def keyfilename
    "#{self.email}-#{self.id}.pub"
  end

  def label
    [self.description, self.email].join(', ')
  end 

private   

  # TODO: handle update (rename key)
  def persist_publickey
    logger.info("Saving key #{self.keyfilename} to disk")
    File.open(keyfile, 'w') do |file|
      file.puts self.source
    end
  end

  def delete_publickey
    logger.info("Deleting key #{self.keyfilename} from disk")        
    File.delete(keyfile)
  end

  def add_to_git
    logger.info("Push key to git")
    git = GitosisAdmin.new
    git.push_key(self.keyfilename, "Added new key #{self.keyfilename}")
  end

  def remove_from_git
    logger.info("Remove key from git")
    git = GitosisAdmin.new
    git.remove_key(self.keyfilename, "Removed key #{self.keyfilename}")
  end

end