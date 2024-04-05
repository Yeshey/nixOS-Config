{ lib, pkgs, ... }:

{
  options.myHome.vscodium = with lib; {
    enable = mkEnableOption "vscodium";
  };

  config = 
    let
			# the latex code: https://stackoverflow.com/questions/56743092/modifying-settings-json-in-vscode-to-add-shell-escape-flag-to-pdflatex-in-latex
			# You need to add this code here as well but you don't know how, so latex works with svgs
			vscUserSettings = builtins.fromJSON (builtins.readFile ./VSCsettings.json);
    in 
		{

			# ====== Making VScodium settings writable ======
			# Allowing VScode to change settings on run time, see last response: https://github.com/nix-community/home-manager/issues/1800
			# VScodium is now free to write to its settings, but they will be overwritten when I run nixos rebuild
			# check also how he implemented in his repository: https://github.com/rgbatty/cauldron (nope!)
			# TODO user = "yeshey";
			home.activation.boforeCheckLinkTargets = let
				user = "yeshey";
			in {
				after = [];
				before = [ "checkLinkTargets" ];
				data = ''
					userDir=/home/${user}/.config/VSCodium/User
					rm -rf $userDir/settings.json

					# as I changed the name to Visual Studio Code, I need to maintain VSC settings too
					userDir2="/home/${user}/.config/Visual Studio Code/User"
					rm -rf $userDir/settings.json
				'';
			};

			home.activation.afterWriteBoundary = 
			let
					userSettings = vscUserSettings;
			in
			{
				after = [ "writeBoundary" ];
				before = [];
				data = ''
					if [ -d ~/.config/VSCodium/User ]; then
						userDir=$HOME/.config/VSCodium/User
						mkdir -p "$userDir"
						rm -rf $userDir/settings.json
						cat \
							${(pkgs.formats.json {}).generate "blabla"
								userSettings} \
							> "$userDir/settings.json"

						# for Code
						userDir3="$HOME/.config/Code/User"
						mkdir -p "$userDir3"
						rm -rf $userDir3/settings.json
						cat \
							${(pkgs.formats.json {}).generate "blabla"
								userSettings} \
							> "$userDir3/settings.json"

						# as I changed the name to Visual Studio Code, I need to maintain VSC settings too
						userDir2="$HOME/.config/Visual Studio Code/User"
						mkdir -p "$userDir2"
						rm -rf $userDir2/settings.json
						cat \
							${(pkgs.formats.json {}).generate "blabla"
								userSettings} \
							> "$userDir2/settings.json"

						# Also for .openvscode-server (I think you can put it here..?)
						userDir4="$HOME/.openvscode-server/data/Machine"
						mkdir -p "$userDir4"
						rm -rf $userDir4/settings.json
						cat \
							${(pkgs.formats.json {}).generate "blabla"
								userSettings} \
							> "$userDir4/settings.json"
					fi
				'';
			};
			# ====== ============================ ======    

	/*
						# for Code
						# userDir3="$HOME/.config/Code/User"
						# mkdir -p "$userDir3"
						# rm -rf $userDir3/settings.json
						# cat \
						#   ${(pkgs.formats.json {}).generate "blabla"
						#     userSettings} \
						#   > "$userDir3/settings.json"
	*/

  	};
}
