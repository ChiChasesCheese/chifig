# conda 只保留一套（cask miniconda），且不自动激活 base；仅 quant/qbot 这类项目用 `conda activate`
for _p in /opt/homebrew/Caskroom/miniconda/base "$HOME/miniconda3" "$HOME/miniforge3"; do
  if [[ -f "$_p/etc/profile.d/conda.sh" ]]; then
    source "$_p/etc/profile.d/conda.sh"
    break
  fi
done
unset _p
