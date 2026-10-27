#!/bin/sh
# Rebuilds a villager's model (assets/models/characters/<who>.glb) from Gary's
# AssetFurnace master file, the way tools/rig_player_a.sh does the player's:
#   tools/rig_villager.sh corin ~/incoming-18oct/Corin_Model/Corin_Master_12_Animations.glb
#   tools/rig_villager.sh tam   ".../Tam the miller model/Tam_Master_11_Animations.glb"
#   tools/rig_villager.sh tilly ".../Tilly model/Unknown_Tilly_Master_11_Animations.glb"
#   tools/rig_villager.sh nell  .../Old_Nell_model/Old_Nell_Master_10_Animations.glb
#   tools/rig_villager.sh hob   ".../Hob model/Hob_Master_8_Animations.glb"
#   tools/rig_villager.sh bram  ".../Bram model/Bram_Master_18_Animations.glb"   (20 Oct)
#   tools/rig_villager.sh corin ".../corin model"      (19 Oct: the folder of his single-clip files)
#   tools/rig_villager.sh farmer   .../farmer_model/New_Character_01_Master_21_Animations.glb    (22 Oct)
#   tools/rig_villager.sh merchant .../merchant_model/New_Character_02_Master_21_Animations.glb  (22 Oct)
#   tools/rig_villager.sh trader   .../trader_model/New_Character_03_Master_21_Animations.glb    (22 Oct)
#   tools/rig_villager.sh elder    ".../card game folder/New_Character_04_Master_21_Animations.glb"  (23 Oct)
#   tools/rig_villager.sh child_b  ".../card game folder/New_Character_05_Master_21_Animations.glb"  (23 Oct)
#   tools/rig_villager.sh child_c  ".../card game folder/New_Character_06_Master_21_Animations.glb"  (23 Oct)
#   tools/rig_villager.sh refugee   .../Travel_Worn_Woman_Master_21_Animations.glb  (27 Oct)
#   tools/rig_villager.sh corin_mam .../Cornis_mam.glb                                (27 Oct)
#   tools/rig_villager.sh krell     .../Huntmaster_Krel.glb                           (27 Oct)
# then `godot --headless --import`, re-render their portrait and check them
# (README, Story mode). Each keeps all of its own clips; the game's clips it
# lacks are fitted to it from clips/shared.glb, Bram's lift and (Corin, who
# came without a walk) the player's walk, run, sit and wave. AssetFurnace's
# walk and run lift the head 14 degrees above the idle's, so it's levelled.
set -e
cd "$(dirname "$0")/.."
who="$1"
src="$2"
out="assets/models/characters/$who.glb"
GAME="talk,duel_idle,play_card,victory,defeat,fall,look_up"
case "$who" in
corin)
	# a young man a little shorter than the player. Given a folder of
	# single-clip AssetFurnace files (..._idle.glb, _walk, _run, _jump, _sit,
	# _wave, _cheer, _dance, _punch, _death), the idle file is the body and
	# the others lend their one clip each (the same rig), so he'd walk, run,
	# sit and wave as himself; his 18 October fighting clips come over from
	# the model he had. (The "corin model" folder of 19 October turned out to
	# hold Old Nell's files, so his 18 October model stands until his come.)
	if [ -d "$src" ]; then
		# (copied to a folder with no spaces in its name first)
		tmp=$(mktemp -d)
		cp "$src"/*.glb "$tmp"/
		# the body: the idle file, or (Gary's 20 October folder, "Corins extra
		# movements", which has only walk, run, sit and wave) the walk file,
		# with his idle and everything else from the 18 October model
		idle=$(ls "$tmp"/*_idle.glb 2>/dev/null | head -1)
		body="$idle"
		bodyclip=idle
		if [ -z "$body" ]; then
			body=$(ls "$tmp"/*_walk.glb | head -1)
			bodyclip=walk
		fi
		borrow=""
		for c in idle walk run jump sit wave cheer dance punch death; do
			test "$c" = "$bodyclip" && continue
			f=$(ls "$tmp"/*_$c.glb 2>/dev/null | head -1)
			test -n "$f" && borrow="$borrow --borrow $f:*=$c"
		done
		# (his 18 October model, as committed: the one with the fighting clips,
		# and his idle, jump, cheer, dance, punch and death when the folder
		# lacks them)
		git show 0afe166:assets/models/characters/corin.glb > /tmp/corin_18oct.glb
		set -f   # (the "*=" in $borrow is for rig_character.py, not the shell)
		python3 tools/rig_character.py "$body" "$out" --name Corin --height 1.72 \
			--rename ArmatureAction=$bodyclip \
			--cycle walk --cycle run --seam idle --seam dance \
			$borrow \
			--borrow /tmp/corin_18oct.glb:idle,jump,cheer,dance,punch,death \
			--borrow "assets/models/characters/clips/shared.glb:$GAME" \
			--borrow assets/models/characters/bram.glb:lift \
			--borrow /tmp/corin_18oct.glb:fight_stance,flying_kick,hit_react,kata,kick,punch_combo \
			--head-up=-12:walk,run
		set +f
	else
		# the 18 October master: no walk, run, sit or wave of his own
		python3 tools/rig_character.py "$src" "$out" --name Corin --height 1.72 \
			--seam idle --seam fight_stance --seam dance \
			--borrow "assets/models/characters/clips/shared.glb:$GAME" \
			--borrow assets/models/characters/bram.glb:lift \
			--borrow assets/models/characters/player_a.glb:walk,run,sit,wave \
			--head-up=-12:walk,run
	fi
	;;
bram)
	# the innkeeper (grey-haired, in his sixties, in a leather apron): Gary's
	# 20 October master with his own idle, walk, run, sit, wave, dance and
	# fighting clips. His lift (he lifts the lantern crate, and everyone
	# borrows it) and his cheer come over from the stand-in model he had
	# (committed on 11 October; git show 3c521d9:... is the last of it)
	git show 3c521d9:assets/models/characters/bram.glb > /tmp/bram_standin.glb
	python3 tools/rig_character.py "$src" "$out" --name Bram --height 1.84 \
		--cycle walk --cycle run --seam idle --seam dance --seam fight_stance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow /tmp/bram_standin.glb:lift,cheer \
		--head-up=-12:walk,run
	;;
hob)
	# a farmer (South Asian, in his fifties, broad and bald, a red neckerchief):
	# Gary's 26 October model (Hob_new_model.glb, his new look from the Cast
	# tab: a 34-joint rig with 22 clips retargeted from a library, 0.9 m tall
	# as made) replaced his 19 October one; his own walk and run
	python3 tools/rig_character.py "$src" "$out" --name Hob --height 1.80 \
		--cycle walk --cycle run --cycle sneak --seam idle --seam dance --seam fight_stance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run
	;;
ned)
	# the fiddler (a Black man in his seventies, white beard, waistcoat, his
	# fiddle on his back): Gary's 26 October model, a 52-joint rig with one
	# clip, his idle (sent as Hob_3d_model.glb). Everything else comes from
	# the player (walk, run and the rest) and the game's shared clips.
	python3 tools/rig_character.py "$src" "$out" --name Ned --height 1.72 \
		--rename ArmatureAction=idle --seam idle \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--borrow assets/models/characters/player_a.glb:walk,run,sneak,sit,wave,cheer,dance,jump,hit_react,death,fight_stance,punch \
		--head-up=-12:walk,run
	;;
tam)
	# a big man
	python3 tools/rig_character.py "$src" "$out" --name Tam --height 1.88 \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run
	;;
tilly)
	# a girl of about seven; her leather satchel and its strap (bound to her
	# arms by AssetFurnace: the bag stretched after her hand when she held her
	# card out) move with her body
	python3 tools/rig_character.py "$src" "$out" --name Tilly --height 1.25 \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run \
		--free-of-arms 0.40,0.27,0.21:0.14
	;;
nell)
	# a small, stooped old woman with a walking stick (part of her mesh, in her
	# right hand). Gary's 25 October model (Nell_model.glb, her new look from
	# the Cast tab: the blue headscarf, the cream shawl, the plum dress; a
	# 21-joint rig with 22 clips retargeted from a library, 0.9 m tall as made)
	# replaced his 18 October one. Its clips hang her right hand loose at her
	# side, so the stick (rigid to that hand) would point back through her
	# skirt: that arm stays as in the rest pose, hand on the stick, wherever
	# she stands, walks, talks, cheers or dances; her wave and her fall move
	# it (she waves the stick).
	python3 tools/rig_character.py "$src" "$out" --name "Old Nell" --height 1.50 \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--hold-arm Right:rest:idle,walk,run,sneak,talk,cheer,dance,look_up,duel_idle,play_card,victory,defeat,lift \
		--head-up=-12:walk,run
	# the stick itself follows her right hand alone (AssetFurnace bound its
	# top to her fingers and its foot to her toes, and it bent as she danced)
	python3 tools/stick_weights.py "$out" --fix
	;;
farmer|merchant|trader)
	# the crowd's looks (22 October): AssetFurnace masters with the player's
	# 21 clips each. The farmer (New Character 01) and the trader (03) are
	# 52-joint rigs with Player B's clips retargeted; the merchant (02, the red
	# waistcoat and the beard) is a 34-joint rig like Tam's, with ten clips
	# from Tam's library and ten cross-rig from Player B (fingers dropped).
	case "$who" in
	farmer) name="Farmer"; height=1.78 ;;
	merchant) name="Merchant"; height=1.72 ;;
	trader) name="Trader"; height=1.80 ;;
	esac
	python3 tools/rig_character.py "$src" "$out" --name "$name" --height "$height" \
		--cycle walk --cycle run --cycle sneak --seam idle --seam dance --seam fight_stance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run
	;;
elder|child_b|child_c|refugee|corin_mam|krell)
	# the last cut-outs to become models (Gary's 23 October masters, from his
	# "card game folder": the village elder (New Character 04, the old woman
	# in the blue dress and shawl), the two children of the green and the
	# Lantern Night (05 the boy in the green tunic, 06 the girl in the red
	# dress) and, when it comes, the refugee woman at Solhaven's gate, whose
	# sheet came 22 October). Built like the crowd's looks: 52-joint rigs with
	# the player's 21 clips. The masters come 0.9 m tall whatever the figure,
	# so the heights are set here: the children about ten (Tilly, at 1.25, is
	# seven), the elder a little stooped.
	case "$who" in
	elder) name="Elder"; height=1.62 ;;
	child_b) name="Child B"; height=1.34 ;;
	child_c) name="Child C"; height=1.30 ;;
	refugee) name="Refugee"; height=1.64 ;;
	# (27 October: Gary's Corin's mam at the bakery door, and Huntmaster
	# Krell of Ironvault, the same 52-joint rigs with the 21 clips and a
	# get_out_of_bed; the refugee woman came the same day, as
	# Travel_Worn_Woman_Master_21_Animations.glb)
	corin_mam) name="Corin's Mam"; height=1.66 ;;
	krell) name="Huntmaster Krell"; height=1.80 ;;
	esac
	python3 tools/rig_character.py "$src" "$out" --name "$name" --height "$height" \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run
	;;
*)
	echo "usage: $0 bram|corin|tam|tilly|nell|hob|ned|farmer|merchant|trader|elder|child_b|child_c|refugee|corin_mam|krell <master.glb or folder of single-clip files>" >&2
	exit 1
	;;
esac
