require 'base64'
require 'json'

class Github
  include HTTParty
  # for debugging HTTParty
  # debug_output $stdout

  BASE_URI = "https://api.github.com"
  
  def access_token=(token)
    @access_token = token
  end
  
  def initialize(owner, repo)
    @owner = owner
    @repo = repo
    @access_token = nil
  end
   
  def current_user
    response = self.class.get("#{BASE_URI}/user?access_token=#{@access_token}")
    response.parsed_response
  end
    
  def ref(branch)
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/refs/heads/#{branch}?access_token=#{@access_token}")
    response.parsed_response
  end
  
  def refs
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/refs")
    response.parsed_response
  end
    
  def commit(sha)
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/commits/#{sha}")
    response.parsed_response
  end
    
  def branch(name)
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/branches/#{name}?access_token=#{@access_token}")
    response.parsed_response
  end
    
  def tree(sha)
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/trees/#{sha}?access_token=#{@access_token}")
    response.parsed_response
  end
    
  def tree_recursive(sha)
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/trees/#{sha}?recursive=1")
    response.parsed_response
  end
    
  def blob(sha)
    response = self.class.get("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/blobs/#{sha}")
    response.parsed_response
  end
  
  def authorizations(username, password)
    options = {
      headers: headers,
      basic_auth: { username: username, password: password }
    }
    response = self.class.get("#{BASE_URI}/authorizations", options)
    response.parsed_response
  end
  
  # content needs to already be encoded
  def create_blob(content)
    options = {
      headers: headers,
      body: {
        content: content,
        encoding: "base64"
      }.to_json
    }
    response = self.class.post("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/blobs", options)
    response.parsed_response
  end
    
  def create_tree(base_tree_sha, blobs)
    options = {
        headers: headers,
        body: {
          base_tree: base_tree_sha,
          tree: blobs
        }.to_json
    }
    response = self.class.post("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/trees", options)
    response.parsed_response
  end

  def create_commit(message, parents, tree)
    options = {
      headers: headers,
      body: {
        message: message,
        tree: tree,
        parents: parents
      }.to_json
    }
    response = self.class.post("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/commits", options)
    response.parsed_response
  end
  
  def create_ref(branch, commit_sha)
    options = {
      headers: headers,
      body: {
        ref: "refs/heads/#{branch}",
        sha: commit_sha
      }.to_json
    }
    response = self.class.post("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/refs", options)
    response.parsed_response
  end
    
  def patch_ref(branch, commit_sha)
    options = {
      headers: headers,
      body: {
        sha: commit_sha,
        force: false
      }.to_json
    }
    response = self.class.patch("#{BASE_URI}/repos/#{@owner}/#{@repo}/git/refs/heads/#{branch}", options)
    response.parsed_response
  end

  def create_authorization(username, password, client_id, client_secret)
    options = {
      headers: headers,
      basic_auth: { username: username, password: password },
      body: {
        scopes: ["repo"],
        client_id: client_id,
        client_secret: client_secret
      }.to_json
    }
    response = self.class.post("#{BASE_URI}/authorizations", options)
    response.parsed_response
  end
  
  def create_pull_request(title, body, from_branch, into_branch = "master")
    options = {
      headers: headers,
      body: {
        title: title,
        body: body,
        base: into_branch,
        head: "#{from_branch}"
      }.to_json
    }
    response = self.class.post("#{BASE_URI}/repos/#{@owner}/#{@repo}/pulls", options)
    response.parsed_response
  end
  
private

  def headers()
    h = {
      'Accept' => 'application/json',
      'Content-Type' => "application/json"
    }
    if !@access_token.nil? && !@access_token.empty?
      h['Authorization'] = "token #{@access_token}"
    end
    h
  end

end