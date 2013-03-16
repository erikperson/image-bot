require 'rubygems'
require 'sinatra'
require 'sinatra/config_file'
require 'httparty'
require 'image_optim'
require 'base64'
require 'tempfile'
require './github'

config_file 'config/settings.yml'
set :logging, :true

def valid_image?(path)
  path.end_with?("png")
end

def find_image_paths(commits)
  paths = commits.map do |commit|
    all_paths = (commit["added"] || []) + (commit["modified"] | [])
    image_paths = all_paths.grep(/\.png$/)
    image_paths
  end
  paths.flatten.uniq
end

def find_commit_ids(commits)
  commits.map do |commit|
    commit["id"]
  end
end

def image_tree_items_from_commit(gh, commit)
  tree_sha = commit["tree"]["sha"]
    
  full_tree = gh.tree_recursive(tree_sha)
    
  full_tree["tree"].select do |object|
    object["type"] == "blob" && valid_image?(object["path"])
  end
end

def compressible_blobs(blobs, paths)
  blobs.select do |blob|
    paths.include?(blob["path"])
  end
end

def save_image_files_from_blob_tree_items(gh, items)
  new_blobs = []
  image_optim = ImageOptim.new(pngout: false)
  items.each do |item|
    sha = item["sha"]
    blob = gh.blob(sha)
    if blob["encoding"] == "base64"
      Tempfile.open(sha) do |temp|
        original_size = blob["content"].length
        temp.write(Base64.decode64(blob["content"]))
        temp.flush
        
        compressed_path = image_optim.optimize_image(temp.path)
        
        encoded = nil
        File.open(compressed_path) do |file|
          encoded = Base64.strict_encode64(file.read)
        end

        if encoded.length < original_size
          new_blob = gh.create_blob(encoded)
          b = item.clone
          b.delete("url")
          b["sha"] = new_blob["sha"]
          new_blobs<< b
          logger.info "Compressed blob: #{new_blob["sha"]}"
        else
          logger.info "Blob not compressible: #{blob["sha"]}"
        end
      end
    end
  end
  
  new_blobs
end

def get_or_create_auth_token(gh)
  authorizations = gh.authorizations(settings.bot_username, settings.bot_password)
  existing = authorizations.find { |a| a["app"]["name"] == settings.app_name }
  
  if !existing
    existing = gh.create_authorization(settings.bot_username, settings.bot_password, settings.client_id, settings.client_secret)
  end
  
  if existing && existing.has_key?("token")
    gh.access_token = existing["token"]
    return true
  end
  false
end

def update_branch_with_commit(gh, commit)
  existing_refs = gh.refs()
  existing_ref = existing_refs.find do |ref|
    ref["ref"] =~ /refs\/heads\/#{settings.branch}/
  end

  if existing_ref.nil?
    existing_ref = gh.create_ref(settings.branch, commit["sha"])
    logger.info "Created branch: #{existing_ref["ref"]}"
  else
    existing_ref = gh.patch_ref(settings.branch, commit["sha"])
    logger.info "Updated branch: #{existing_ref["ref"]}"
  end
  existing_ref
end

post '/' do
  gh = Github.new(settings.repo_owner, settings.repo_name)
  
  success = get_or_create_auth_token(gh)
  if !success
    logger.error "Unable to create auth token. Check username/password and client id/secret."
    return 403
  end

  payload = JSON.parse(params[:payload])
  
  paths = find_image_paths(payload["commits"])
  
  head_commit = gh.commit(payload["after"])
  items = image_tree_items_from_commit(gh, head_commit)
  
  blobs = compressible_blobs(items, paths)
  
  new_blobs = save_image_files_from_blob_tree_items(gh, blobs)
  
  if new_blobs.length > 0
    new_tree = gh.create_tree(head_commit["tree"]["sha"], new_blobs)
  
    logger.info "New tree: #{new_tree["sha"]}"
  
    message = "#{settings.app_name} compressed #{new_blobs.length} image#{new_blobs.length == 1 ? "" : "s"}"
    new_commit = gh.create_commit(message, [head_commit["sha"]], new_tree["sha"])
  
    logger.info "New commit: #{new_commit["sha"]}"
  
    ref = update_branch_with_commit(gh, new_commit)
    if ref
      body = new_blobs.map { |b| "* #{b["path"]}" }.join("\n")
      gh.create_pull_request(message, body, settings.branch)
    end
    
  end
  
end
