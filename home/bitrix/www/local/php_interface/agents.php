<?php

/**
 * Reset theme to default for online users
 */

function resetThemeToDefault()
{
	\Bitrix\Main\Loader::includeModule('intranet');
	$dbRes = CUser::GetList('id', 'asc', ["ACTIVE" => "Y", "LAST_ACTIVITY" => "1200"], ["FIELDS" => ["ID"]]);
	while ($user = $dbRes->Fetch())
	{
		if(CUser::isOnline($user["ID"]))
		{
			$themePicker = new \Bitrix\Intranet\Integration\Templates\Bitrix24\ThemePicker('bitrix24', 's1', $user["ID"]);
			$themePicker->setCurrentThemeId($themePicker->getDefaultThemeId(), $user["ID"]);
		}
	}
	return "resetThemeToDefault();";
}