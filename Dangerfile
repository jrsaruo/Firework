# Validate the base branch
is_to_main_branch = github.branch_for_base == "main"
is_from_release_or_hotfix_branch = github.branch_for_head.start_with?("release", "hotfix")
if is_to_main_branch && !is_from_release_or_hotfix_branch
    warn("You are attempting to merge a branch that is neither release nor hotfix into the main branch.")
end
