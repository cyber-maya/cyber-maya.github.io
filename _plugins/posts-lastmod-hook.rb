#!/usr/bin/env ruby
#
# Check for changed posts and set last_modified_at using Git metadata when available.
# Falls back gracefully when Git is not installed or not a Git repo.

def windows_platform?
	Gem.win_platform?
end

def dev_null_path
	windows_platform? ? 'NUL' : '/dev/null'
end

def git_available?
	# system returns true on success, false for non-zero exit, nil when command not found
	system("git --version >#{dev_null_path} 2>&1") ? true : false
end

def in_git_repo?(dir)
	File.directory?(File.join(dir, '.git'))
end

Jekyll::Hooks.register :posts, :post_init do |post|
	site_source = post.respond_to?(:site) && post.site ? post.site.source : Dir.pwd

	unless git_available? && in_git_repo?(site_source)
		Jekyll.logger.debug 'posts-lastmod-hook:', 'Skipping Git lookup (git unavailable or not a git repo)'
		next
	end

	begin
		commit_count = `git rev-list --count HEAD "#{ post.path }"`.to_i
		if commit_count > 1
			lastmod_date = `git log -1 --pretty="%ad" --date=iso "#{ post.path }"`.strip
			post.data['last_modified_at'] = lastmod_date unless lastmod_date.empty?
		end
	rescue Errno::ENOENT
		Jekyll.logger.warn 'posts-lastmod-hook:', "git not found; skipping last_modified_at for #{ post.path }"
	rescue => e
		Jekyll.logger.warn 'posts-lastmod-hook:', "Failed to retrieve git info for #{ post.path }: #{ e.class }: #{ e.message }"
	end
end
