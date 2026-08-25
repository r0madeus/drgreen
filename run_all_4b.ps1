& "C:\Users\Melih Uçgun\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless -s tests/qa/test_runtime_boot.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "C:\Users\Melih Uçgun\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless -s tests/qa/run_p4a_qa.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "C:\Users\Melih Uçgun\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless -s tests/qa/run_4b_baseline.gd
