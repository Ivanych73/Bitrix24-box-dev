<?
if (!defined("B_PROLOG_INCLUDED") || B_PROLOG_INCLUDED!==true)die();

\Bitrix\Main\UI\Extension::load(['ui.design-tokens', 'ui.fonts.opensans']);

$this->setFrameMode(true);
$this->SetViewTarget("sidebar", 500);
?>
<div class="b24-app-block b24-app-desktop">
	<div class="b24-app-block-header"><?=GetMessage("B24_BANNER_CUSTOM_MESSENGER_TITLE") ?></div>
	<div class="b24-app-block-content">
		<!--<a href="mailto:support@itex.ru" class="b24-app-block-content-apps">Задайте вопрос по электронной почте</a>-->
		<a href="/mail/message/new?email=support@itex.ru"class="b24-app-block-content-apps">Задайте вопрос по электронной почте</a>
		<div style="clear:both"></div>
	</div>
</div>
<a href="https://rshbins.webportal.ru" class="b24-app-block-content-apps">
<div class="b24-app-block b24-app-mobile">
	<!--
	<div class="b24-app-block-header"><?=GetMessage("B24_BANNER_CUSTOM_MOBILE_TITLE") ?></div>
	-->
	<div class="b24-app-block-content">
		<img src=<?=$this->GetFolder()?>/images/portal_logo.png width=50%>
		<div style="clear:both"></div>
	</div>
</div>
</a>