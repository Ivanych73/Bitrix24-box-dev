<?php

AddEventHandler("disk", "OnAfterAddFile", ["DiskEventHandlers", "BlockFileUpload"]);

/**
 * A class for custom disk event handlers
 */
class DiskEventHandlers
{
    /**
    * Constant defined not to use magic numbers in code
    */
	private const SYSTEM_USER_ID = 0;
    /**
     * Constant defined not to use magic numbers in code
     */
	private const ADMIN_USER_ID = 1;

    /**
     * @param array $arFilter filter for search
     * 
     * @return string group id
     */
	private static function GetGroupIdByFilter(Array $arFilter)
	{
		$dbRes = CGroup::GetList($by = "c_sort", $order = "asc", $arFilter);
		$group = $dbRes->Fetch();
		return $group["ID"];
	}

	/**
	 * Block file uploading for users not in selected groups
	 * 
	 * According to client's request, block file uploading for all users
	 * except administrators and portal administration
	 * Using OnAfterAddFile event, because there's no OnBeforeAddFile event
	 * Complex filter logic like "LOGIC" => "OR" doesn't seem to work in CUser::GetUserGroup,
	 * so using 2 GetGroupIdByFilter() function calls.
	 * When file uploading to common disk $file->getId() returns disk object id, 
	 * so using \Bitrix\Disk\File::load to get file id
	 * 
	 * @param file $file 
	 * 
	 * @return void
	 */

	static function BlockFileUpload($file)
	{
		$arGroupsCanUploadFiles[] = self::GetGroupIdByFilter(["ADMIN" => "Y"]);
		$arGroupsCanUploadFiles[] = self::GetGroupIdByFilter(["NAME" => "Администрация портала"]);
		$iUserId = $GLOBALS["USER"]->GetID();
		$arUserGroups = CUser::GetUserGroup($iUserId);
		$bUserCanUploadFiles = false;
		foreach ($arUserGroups as $element)
		{
			if (in_array($element, $arGroupsCanUploadFiles))
			{
				$bUserCanUploadFiles = true;
			}
		}
		if(!$bUserCanUploadFiles)
		{
			\Bitrix\Main\Loader::includeModule('im');
			$arFields = array(
				"FROM_USER_ID" => self::SYSTEM_USER_ID,
				"SYSTEM" => "Y",
				"MESSAGE"  => "Только администраторы могут добавлять файлы!",
				"MESSAGE_TYPE" => IM_MESSAGE_SYSTEM,
				"TO_USER_ID" => $iUserId,
			);
			CIMNotify::Add($arFields);
			\Bitrix\Main\Loader::IncludeModule('disk');
			$iFileId = $file->GetFileID();
			$diskFile = \Bitrix\Disk\File::load([
			'=FILE_ID' => $iFileId
			]);
			$diskFile->delete(self::ADMIN_USER_ID);
		}
	}
}