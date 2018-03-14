unit bookSearchForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  CheckLst, StdCtrls,bookListView, ComCtrls, Menus,librarySearcher,booklistreader,TreeListView,math,
  librarySearcherAccess,multipagetemplate;

type

  { TbookSearchFrm }

  TbookSearchFrm = class(TForm)
    detailPanel: TPanel;
    holdingsPanel: TPanel;
    searchLocationRegion: TComboBox;
    menuCopyValue: TMenuItem;
    menuCopyRow: TMenuItem;
    PopupMenu1: TPopupMenu;
    holdingsSplitter: TSplitter;
    startAutoSearchButton: TButton;
    searchBranch: TComboBox;
    homeBranch: TComboBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label2xx: TLabel;
    searchBranchLabel: TLabel;
    homeBranchLabel: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LabelOrder: TLabel;
    LabelOrderFor: TLabel;
    LabelSaveTo: TLabel;
    saveToAccountMenu: TPopupMenu;
    orderForAccountMenu: TPopupMenu;
    ScrollBox1: TScrollBox;
    searchAuthor: TComboBox;
    searchISBN: TComboBox;
    searchKeywords: TComboBox;
    searchTitle: TComboBox;
    searchYear: TComboBox;
    startSearch: TButton;
    displayImage: TCheckBox;
    displayInternalProperties: TCheckBox;
    detailPanelHolder: TPanel;
    Image1: TImage;
    Label2: TLabel;
    linkLabelDigibib: TLabel;
    linkLabelBib: TLabel;
    linkLabelAmazon: TLabel;
    linkLabelGoogle: TLabel;
    Panel1: TPanel;
    searchLocation: TComboBox;
    searchSelectionList: TCheckListBox;
    Label1: TLabel;
    optionPanel: TPanel;
    bookListPanel: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    StatusBar1: TStatusBar;
    autoSearchContinueTimer: TTimer;
    procedure autoSearchContinueTimerTimer(Sender: TObject);
    procedure bookListSelect(sender: TObject; item: TTreeListItem);
    procedure bookListVScrollBarChange(Sender: TObject);
    procedure menuCopyRowClick(Sender: TObject);
    procedure menuCopyValueClick(Sender: TObject);
    procedure searchKeywordsChange(Sender: TObject);
    procedure searchLocationRegionSelect(Sender: TObject);
    procedure startAutoSearchButtonClick(Sender: TObject);
    procedure detaillistClickAtRecordItem(sender: TObject; recorditem: TTreeListRecordItem);
    procedure detaillistCustomRecordItemDraw(sender: TObject; eventTyp_cdet: TCustomDrawEventTyp; recordItem: TTreeListRecordItem;
      var defaultDraw: Boolean);
    procedure detaillistMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure searcherAccessConnected(Sender: TObject);
    procedure displayImageChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Label12Click(Sender: TObject);
    procedure LabelOrderClick(Sender: TObject);
    procedure LabelOrderForClick(Sender: TObject);
    procedure LabelSaveToClick(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure searchAuthorEnter(Sender: TObject);
    procedure searchAuthorExit(Sender: TObject);
    procedure searcherAccessOrderComplete(sender: TObject; book: TBook);
    procedure searcherAccessOrderConfirm(sender: TObject; book: TBook);
    procedure searcherAccessPendingMessageCompleted(Sender: TObject);
    procedure searcherAccessTakePendingMessage(sender: TObject; book: TBook; pendingMessage: TPendingMessage);
    procedure searchTitleChange(Sender: TObject);
    procedure startSearchClick(Sender: TObject);
    procedure displayInternalPropertiesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure linkLabelDigibibClick(Sender: TObject);
    procedure optionPanelClick(Sender: TObject);
    procedure searcherAccessDetailsComplete(sender: TObject; book: TBook);
    procedure searcherAccessException(Sender: TObject);
    procedure searcherAccessImageComplete(sender: TObject; book: TBook);
    procedure searcherAccessSearchComplete(sender: TObject; firstPage, nextPageAvailable: boolean);
    procedure searchLocationSelect(Sender: TObject);
    procedure searchSelectionListClickCheck(Sender: TObject);
  private
    { private declarations }
    locations: TSearchableLocations;
    selectedLibrariesPerLocation: TStringList;
    autoSearchPhase: (aspConnecting, aspConnected, aspSearching, aspSearched, aspSearchingDetails, aspSearchedDetails);
    autoSearchDetailCount: integer;
    procedure makeSearcherAccess;
    function currentLocationRegionConfig: string;
    procedure updateBranches;
  public
    { public declarations }
    bookList: TBookListView;
    detaillist: TTreeListView;
    detaillistLastClickedRecordItem: TTreeListRecordItem;
    holdings: TBookListView;
    searcherAccess: TLibrarySearcherAccess;
    newSearcherAccess: TLibrarySearcherAccess;
    nextPageAvailable: boolean;
    displayedBook: TBook;
    researchedBook: TBook;
    procedure bookListHoldingsSelect(sender: TObject; item: TTreeListItem);
    procedure detaillistMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    function displayDetails(book: TBook=nil): longint; //0: no details, 1: detail, no image, 2: everything
    function cloneDisplayedBook: TBook;
    procedure selectBookToReSearch(book: TBook);
    procedure loadDefaults;
    procedure saveDefaults;
  public
    saveToDefaultAccountID, orderForDefaultAccountID: string;
    procedure changeDefaultSaveToAccount(sender:tobject);
    procedure changeDefaultOrderForAccount(sender:tobject);
  end;

var
   bookSearchFrm: TbookSearchFrm;
const SB_PANEL_FOUND_COUNT=1;
      SB_PANEL_SEARCH_STATUS=0;
implementation

uses applicationconfig,applicationdesktopconfig, libraryParser,simplexmlparser,bbdebugtools,bookWatchMain,bbutils,LCLType,libraryAccess,LCLIntf,strutils,Clipbrd,inputlistbox;

{ TbookSearchFrm }
//TODO: fehler bei keinem ergebnis
resourcestring
  rsPropertyName = 'Eigenschaftsname';
  rsValue = 'Wert';
  rsWait = 'Warte...';
  rsSearching = 'Suche Medien...';
  rsBytesHidden = '<%s Bytes ausgeblendet>';
  rsPropertiesNormal = 'normale Eigenschaften';
  rsPropertiesInternal = 'interne Eigenschaften';
  rsPropertiesEmpty = 'leere Eigenschaften';
  rsBookPropertyPublisher = 'Verlag';
  rsBookPropertyFirstTime = 'Erstes Vorkommen';
  rsBookPropertyLastTime = 'Letztes Vorkommen';
  rsBookPropertyRenewCount = 'Anzahl Verlängerungen';
  rsRequestOrder = 'Vormerken/Bestellen';
  rsSearchingDetails = 'Suche Details für dieses Medium...';
  rsLoadingNextPage = 'Lade nächste Seite...';
  rsSearchComplete = 'Suche abgeschlossen';
  rsNoSelection = 'Kein Medium ausgewählt';
  rsNoLinkKnown = 'Leider kann ich das ausgewählte Medium nicht in dieser Seite öffnen, da ich den nötigen Link nicht kenne';
  rsSearchingCover = 'Suche Titelbild...';
  rsSearchPartiallyComplete = 'Suche abgeschlossen (mehr Ergebnisse verfügbar)';
  rsExistsOverrideConfirm = 'Das Medium existiert bereits als "%s", soll es mit "%s" überschrieben werden?';
  rsOverrideConfirm = 'Soll das markierte Medium "%s" mit "%s" überschrieben werden?';
  rsChooseOrder = 'Es gibt mehrere vormerkbare/Bestellbare Exemplare. Welches wollen Sie?';
  rsNoHoldingSelected = 'Es wurde nicht ausgewählt, welches Exemplar bestellt werden soll. (in der unteren Liste)';
  rsOrderConfirm = 'Soll "%s" bestellt werden?';
  rsOrderComplete = 'Das Buch "%s" wurde ohne Fehler vorgemerkt. %s';
  rsCount = '%s Treffer';
  rsCountSelected = '%D / %D Treffer';
  rsFor = 'für';
  rsIn = 'in';


procedure TbookSearchFrm.FormCreate(Sender: TObject);
begin
  selectedLibrariesPerLocation:= TStringList.Create;
  loadDefaults;

  {list:=TList.Create;
  for i:=searchSelectionList.Items.count-1 downto 0 do begin
    libraryManager.enumerateLibrariesWithValue('Location',searchSelectionList.Items[i],list);
    for j:=list.count-1 downto 0 do
      searchSelectionList.items.InsertObject(i+1,'   '+tlibrary(list[j]).prettyNameLong,tobject(list[j]));
  end;
  list.free;  }
  

  bookList:=TBookListView.create(self,false);
  booklist.addColumn('author');
  booklist.addColumn('title');
  booklist.addColumn('year');
  booklist.addColumn('status');
  bookList.Parent:=bookListPanel;
  booklist.deserializeColumnWidths(userConfig.ReadString('BookSearcher','ListColumnWidths','200,200,50,75'));
  booklist.OnSelect:=@bookListSelect;
  bookList.OnVScrollBarChange:=@bookListVScrollBarChange;

  searcherAccess := nil;

  detaillist:=TTreeListView.Create(self);
  detaillist.Parent:=detailPanel;
  detaillist.align:=alClient;
  detaillist.columns.Clear;
  detaillist.PopupMenu := PopupMenu1;
  with detaillist.columns.Add do begin
    text:=rsPropertyName;
    width:=170;
  end;
  with detaillist.columns.Add do begin
    text:=rsValue;
    width:=400;
  end;
  detaillist.OnCustomRecordItemDraw:=@detaillistCustomRecordItemDraw;
  detaillist.OnClickAtRecordItem:=@detaillistClickAtRecordItem;
  detaillist.OnMouseMove:=@detaillistMouseMove;
  detaillist.OnMouseDown:=@detaillistMouseDown;

  holdings := TBookListView.create(self, false);
  holdings.Parent := holdingsPanel;
  holdings.align:=alClient;
  holdings.OnSelect:=@bookListHoldingsSelect;
  holdings.PopupMenu := PopupMenu1;
  holdings.OnCustomRecordItemDraw:=@detaillistCustomRecordItemDraw;
  holdings.OnClickAtRecordItem:=@detaillistClickAtRecordItem;
  holdings.OnMouseMove:=@detaillistMouseMove;
  holdings.OnMouseDown:=@detaillistMouseDown;

  Image1.Width:=0;

  if debugMode then begin
    startAutoSearchButton.Visible := true;
  end;
end;

procedure TbookSearchFrm.startSearchClick(Sender: TObject);
  procedure addCbHistory(cb: TComboBox);
  var
    temp: TCaption;
    maxCount: LongInt;
  begin
    if (cb.text='') or (cb.Items.IndexOf(cb.Text)>=0) then exit;
    temp := cb.Text;
    cb.Items.Insert(0,temp);
    maxCount := userConfig.ReadInteger('BookSearcher', 'HistoryMaxLength', 15);
    while cb.Items.Count>maxCount do cb.Items.Delete(maxCount);
    cb.Text := temp; //lines above sometimes erase text
  end;
var i:longint;
begin
  displayedBook:=nil;
  nextPageAvailable:=false;

  if newSearcherAccess <> nil then begin
    if (searcherAccess <> nil) then begin
      searcherAccess.free;;
    end;
    searcherAccess := newSearcherAccess;
    newSearcherAccess := nil;
  end;

  i := locations.locations.IndexOf(searchLocation.Text);
  if i = -1 then begin i := 0; if locations.locations.Count = 0 then raise exception.Create('No search templates'); end;

  screen.Cursor:=crHourGlass;

  StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsWait;

  searcherAccess.prepareNewSearchWithoutDisconnect;

  if searcherAccess.searcher = nil then exit;

  //thread pending now, no need to use any locking

  if homeBranch.ItemIndex >= 0 then searcherAccess.searcher.HomeBranch:=homeBranch.ItemIndex;
  if searchBranch.ItemIndex >= 0 then searcherAccess.searcher.SearchBranch:=searchBranch.ItemIndex;

  searcherAccess.searcher.SearchOptions.author:=searchAuthor.Text;
  searcherAccess.searcher.SearchOptions.title:=searchTitle.Text;
  searcherAccess.searcher.SearchOptions.year:=searchYear.Text;
  searcherAccess.searcher.SearchOptions.isbn:=searchISBN.Text;
  setProperty('keywords', searchKeywords.Text, searcherAccess.searcher.SearchOptions.additional);


  searcherAccess.searchAsync;

  StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsSearching;

  addCbHistory(searchAuthor);
  addCbHistory(searchTitle );
  addCbHistory(searchKeywords);
  addCbHistory(searchYear);
  addCbHistory(searchISBN);
end;

procedure TbookSearchFrm.displayInternalPropertiesChange(Sender: TObject);
begin
  displayDetails(nil);
end;

procedure TbookSearchFrm.bookListSelect(sender: TObject; item: TTreeListItem);
var book: tbook;

begin
  if (item=nil) or not (item.Selected) then exit;
  if searcherAccess = nil then exit;
  book:=tbook(item.data.obj);

  if displayDetails() < 1 then begin
    searcherAccess.detailsAsyncSave(book);
    Screen.Cursor:=crHourGlass;
    StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsSearchingDetails;
  end;
end;

procedure TbookSearchFrm.autoSearchContinueTimerTimer(Sender: TObject);
var
  i: Integer;
begin
//  if searcherAccess.operationActive then exit;
  case autoSearchPhase of
    aspConnected: begin
      autoSearchPhase:=aspSearching;
      startSearch.Click;
      exit;
    end;
    aspSearched: begin
      autoSearchDetailCount := min(3, bookList.VisibleRowCount);
    end;
    aspSearchedDetails: begin
      autoSearchDetailCount -= 1;
    end
    else exit;
  end;
  if autoSearchDetailCount <= 0 then begin
    if searchSelectionList.Checked[searchSelectionList.Count-1] then begin
      if searchLocation.ItemIndex = searchLocation.Items.Count - 1 then begin
        autoSearchContinueTimer.Enabled := false;
        exit;
      end;
      searchLocation.ItemIndex := searchLocation.ItemIndex + 1;
      searchLocationSelect(searchLocation);
      for i := 0 to searchSelectionList.Count - 1 do
        searchSelectionList.Checked[i] := false;
      searchSelectionList.Checked[0] := true;

    end else begin
      for i := 0 to searchSelectionList.Count - 2 do
        if searchSelectionList.Checked[i] then begin
          searchSelectionList.Checked[i]  := false;
          searchSelectionList.Checked[i + 1] := true;
          break;
        end;
    end;
    autoSearchPhase:=aspConnecting;
    searchSelectionListClickCheck(searchSelectionList);
    exit;
  end;
                                     ;
//  if bookList.Selected = nil then bookList.Selected := ;
autoSearchPhase:=aspSearchingDetails;
  bookList.Selected := bookList.Items[bookList.Items.IndexOf(bookList.Selected)+1];

end;

procedure TbookSearchFrm.bookListVScrollBarChange(Sender: TObject);
begin
  if nextPageAvailable
     and (bookList.VisibleRowCount > bookList.Items.Count - bookList.TopItemVisualIndex)
     and (searcherAccess<>nil)
     then begin
    nextPageAvailable := false;
    searcherAccess.searchNextAsync;
    StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsLoadingNextPage;
  end;
end;

procedure TbookSearchFrm.menuCopyRowClick(Sender: TObject);
var
  opener: TComponent;
  list: TTreeListView;
  v: String;
  item: TTreeListItem;
  i: Integer;
begin
  opener := ((Sender as TMenuItem).GetParentMenu as TPopupMenu).PopupComponent;
  if opener = holdings then list := holdings
  else list := detaillist;
  item := list.selected;
  if item = nil then exit;
  v := item.Text;
  if list = detaillist then v := v + ': '+ item.RecordItemsText[1]
  else for i := 1 to item.RecordItems.Count - 1 do begin
    if (i = item.RecordItems.Count - 1) and (item.RecordItemsText[i] = '') then continue; //is there a hidden column?
    v := v + '|'+ item.RecordItemsText[i];
  end;
  Clipboard.AsText := v;
end;

procedure TbookSearchFrm.menuCopyValueClick(Sender: TObject);
begin
  if detaillistLastClickedRecordItem = nil then exit;
  Clipboard.AsText := detaillistLastClickedRecordItem.Text;
end;

procedure TbookSearchFrm.searchKeywordsChange(Sender: TObject);
begin

end;

procedure TbookSearchFrm.searchLocationRegionSelect(Sender: TObject);
var
  i: Integer;
  locs: TStringList;
  temp: String;
begin
  i := locations.regions.IndexOf(searchLocationRegion.Text);
  if i < 0 then exit;
  locs := locations.regions.Objects[i] as TStringList;
  searchLocation.Items.Clear;
  for i := 0 to locs.count - 1 do
    searchLocation.Items.add(locs[i]);
  if locs.count = 0 then exit;
  temp := userConfig.ReadString('BookSearcher', currentLocationRegionConfig, '');
  if locs.IndexOf(temp) >= 0 then searchLocation.Text := temp
  else searchLocation.text := locs[0];
  searchLocationSelect(searchLocation);
end;

procedure TbookSearchFrm.startAutoSearchButtonClick(Sender: TObject);
var
  i: Integer;
begin
  autoSearchContinueTimer.Enabled:=true;
 // searchLocation.ItemIndex := 1;
 // searchLocationSelect(searchLocation);
  for i := 0 to searchSelectionList.Count - 1 do
    searchSelectionList.Checked[i] := false;
  searchSelectionList.Checked[0] := true;
  searchSelectionListClickCheck(searchSelectionList);
end;

procedure TbookSearchFrm.detaillistClickAtRecordItem(sender: TObject; recorditem: TTreeListRecordItem);
var
  i: SizeInt;
  temp: String;
begin
  if striContains(recordItem.Text, 'http://') or striContains(recordItem.Text, 'https://') then begin
    i := striIndexOf(recordItem.Text, 'http://');
    if i <= 0 then i := striIndexOf(recordItem.Text, 'https://');
    temp := strCopyFrom(recorditem.Text, i);
    if strContains(temp, ' ') then delete(temp, strIndexOf(temp, ' '), length(temp));
    openURL(temp);
  end;
end;

procedure TbookSearchFrm.detaillistCustomRecordItemDraw(sender: TObject; eventTyp_cdet: TCustomDrawEventTyp;
  recordItem: TTreeListRecordItem; var defaultDraw: Boolean);
begin
  if strContains(recordItem.Text, 'http://') or strContains(recordItem.Text, 'https://') then ttreelistview(sender).Canvas.Font.Color:=clBlue
  else ttreelistview(sender).Canvas.Font.Color:=clBlack;
end;

procedure TbookSearchFrm.detaillistMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  tlv: TTreeListView;
  recordItem: TTreeListRecordItem;
begin
  tlv := TTreeListView(sender);
  recordItem := tlv.GetRecordItemAtPos(x,y);
  if (recorditem <> nil) and (strContains(recordItem.Text, 'http://') or strContains(recordItem.Text, 'https://')) then
     tlv.Cursor:=crHandPoint
    else
     tlv.Cursor:=crDefault;
end;

procedure TbookSearchFrm.updateBranches;
  procedure update(cb: TComboBox; sa: TStringArray; l: TLabel);
  var
    i: Integer;
  begin
    l.Visible:=length(sa) > 0;
    cb.Visible:=length(sa) > 0;
    cb.Clear;
    if length(sa) = 0 then exit;
    for i := 0 to high(sa) do
      cb.Items.Add(sa[i]);
    if cb.ItemIndex < 0 then cb.ItemIndex:=0;
  end;

begin
  newSearcherAccess.beginResultReading;
  try
    update(homeBranch, newSearcherAccess.searcher.HomeBranches, homeBranchLabel);
    update(searchBranch, newSearcherAccess.searcher.SearchBranches, searchBranchLabel);
  finally
    newSearcherAccess.endResultReading;
  end;
end;

procedure TbookSearchFrm.searcherAccessConnected(Sender: TObject);
begin
  if sender <> newSearcherAccess then exit;
  if newSearcherAccess.searcher = nil then exit;
  updateBranches;
  autoSearchPhase:=aspConnected;
end;

procedure TbookSearchFrm.displayImageChange(Sender: TObject);
begin
  displayDetails(nil);
end;

procedure TbookSearchFrm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  saveDefaults;
end;

procedure TbookSearchFrm.FormDeactivate(Sender: TObject);
begin

end;

procedure TbookSearchFrm.FormKeyUp(Sender: TObject; var Key: Word;
 Shift: TShiftState);
begin
 if key = VK_RETURN then startSearch.Click
 else if key = VK_ESCAPE then close
 else exit;
 key:=0;
end;

procedure TbookSearchFrm.Label12Click(Sender: TObject);
var temp, old:TBook;
    acc: TCustomAccountAccess;
    i: Integer;
begin
  if displayedBook = nil then exit;
  if accounts.Count = 0 then exit;

  acc := accounts[0];
  for i:=1 to accounts.Count-1 do
    if accounts.Strings[i] = saveToDefaultAccountID then acc := accounts[i];
  //if acc.isThreadRunning then begin ShowMessage('Während dem Aktualisieren können keine weiteren Medien gespeichert werden.'); exit; end;

  temp := cloneDisplayedBook;

  temp.issueDate:=-2;
  temp.dueDate:=-2;


  if (mainForm.BookList.SelectedBook <> nil) and (mainForm.BookList.SelectedBook.owningAccount = acc) then begin
    old := mainForm.BookList.SelectedBook;
    if (old.author = temp.author) or (old.title = temp.title) or
       striBeginsWith(temp.author,old.author) or striBeginsWith(temp.title, old.title) then
     if confirm(Format(rsExistsOverrideConfirm, [old.toSimpleString(), temp.toSimpleString()])) then begin
       EnterCriticalsection(updateThreadConfig.libraryAccessSection);
       old.author:=temp.author; //don't copy id
       old.title:=temp.title;
       old.year:=temp.year;
       old.isbn:=temp.isbn;
       old.assign(temp);
       acc.save();
       LeaveCriticalsection(updateThreadConfig.libraryAccessSection);
       mainForm.RefreshListView;
       exit;
     end;
    if researchedBook <> nil then
     if confirm(Format(rsOverrideConfirm, [old.toSimpleString(), temp.toSimpleString()])) then begin
       EnterCriticalsection(updateThreadConfig.libraryAccessSection);
       old.author:=temp.author; //don't copy id
       old.title:=temp.title;
       old.year:=temp.year;
       old.isbn:=temp.isbn;
       old.assign(temp);
       acc.save();
       LeaveCriticalsection(updateThreadConfig.libraryAccessSection);
       mainForm.RefreshListView;
       researchedBook := nil;
       exit;
     end;
  end;

  EnterCriticalsection(updateThreadConfig.libraryAccessSection);
  acc.books.old.add(temp);
  acc.save();
  LeaveCriticalsection(updateThreadConfig.libraryAccessSection);
  mainForm.RefreshListView;
  researchedBook := nil;
end;

procedure TbookSearchFrm.LabelOrderClick(Sender: TObject);
var
  acc: TCustomAccountAccess;
  i: Integer;
  orderBook: TBook;
  sl: TStringList;
begin
  if (displayedBook = nil) or (searcherAccess = nil) then exit;
  if accounts.Count = 0 then exit;

  orderBook := displayedBook;
  if displayedBook.holdings <> nil then begin
    if holdings.SelectedBook = nil then begin
      ShowMessage(rsNoHoldingSelected);
      exit;
    end;
    orderBook := holdings.SelectedBook;
  end;

  acc := accounts[0];
  for i:=1 to accounts.Count-1 do
   if accounts.Strings[i] = orderForDefaultAccountID then acc := accounts[i];
  //if acc.isThreadRunning then begin ShowMessage('Während dem Aktualisieren/Verlängern/Vormerken können keine weiteren Medien vorgemerkt werden.'); exit; end;

  searcherAccess.beginBookReading;
  try
    if StrToIntDef(orderBook.getPropertyAdditional('orderable'), 1) > 1 then begin
      sl := TStringList.Create;
      for i :=  0 to StrToIntDef(orderBook.getPropertyAdditional('orderable'), 1) - 1 do
        sl.Add(orderBook.getPropertyAdditional('orderTitle'+inttostr(i)));
      i := InputList('VideLibri', rsChooseOrder, sl );
      sl.free;
      if i < 0 then exit;
      orderBook.setProperty('choosenOrder', inttostr(i));
    end else orderBook.setProperty('choosenOrder', '0');
  finally
    searcherAccess.endBookReading;
  end;

  if not confirm(Format(rsOrderConfirm, [displayedBook.title])) then exit;

  screen.Cursor:=crHourGlass;
  searcherAccess.orderAsync(acc, orderBook);
end;

procedure TbookSearchFrm.LabelOrderForClick(Sender: TObject);
begin
  orderForAccountMenu.PopUp();
end;

procedure TbookSearchFrm.LabelSaveToClick(Sender: TObject);
begin
  saveToAccountMenu.PopUp;
end;

procedure TbookSearchFrm.Label2Click(Sender: TObject);
begin

end;

procedure TbookSearchFrm.searchAuthorEnter(Sender: TObject);
begin
end;

procedure TbookSearchFrm.searchAuthorExit(Sender: TObject);
begin
end;

procedure TbookSearchFrm.searcherAccessOrderComplete(sender: TObject; book: TBook);
var
  acc: TCustomAccountAccess;
  temp: TBook;
begin
  if sender <> searcherAccess then exit;
  //see androidutils/bookSearchForm
  searcherAccess.beginBookReading;
  EnterCriticalSection(updateThreadConfig.libraryAccessSection);
  acc := TCustomAccountAccess(book.owningAccount);
  temp := book.clone; temp.status:=bsOrdered;
  acc.books.current.add(temp);
  temp := book.clone; temp.status:=bsOrdered;
  acc.books.currentUpdate.add(temp); //cannot know which one is the correct one? one will be discarded?
  acc.save();
  LeaveCriticalSection(updateThreadConfig.libraryAccessSection);
  searcherAccess.endBookReading;


  if mainForm <> nil then mainForm.RefreshListView;
  ShowMessage(format(rsOrderComplete, [book.toSimpleString(), LineEnding + LineEnding + book.statusStr])  );
  screen.Cursor:=crDefault;
end;

procedure TbookSearchFrm.searcherAccessOrderConfirm(sender: TObject; book: TBook);
var
  question: String;
  orderConfirmationOptionTitles: String;
  temp: TStringArray;
  i: Integer;
  sl: TStringList;
begin
  if sender <> searcherAccess then exit;

  searcherAccess.beginBookReading;
  question := book.getPropertyAdditional('orderConfirmation');
  orderConfirmationOptionTitles := book.getPropertyAdditional('orderConfirmationOptionTitles');
  searcherAccess.endBookReading;

  question := StringReplace(question, '\n', LineEnding, [rfReplaceAll]);
  if orderConfirmationOptionTitles <> '' then begin
    sl := TStringList.Create;
    temp := strSplit(orderConfirmationOptionTitles, '\|');
    for i := 0 to high(temp) do
      sl.add(temp[i]);
    screen.Cursor:=crDefault;
    i := InputList('VideLibri', question, sl );
    sl.free;
    if i < 0 then exit;


    screen.Cursor:=crHourGlass;

    searcherAccess.beginBookReading;
    book.setProperty('choosenConfirmation', IntToStr(i + 1));
    searcherAccess.endBookReading;

    searcherAccess.orderConfirmedAsync(book);
  end else
    if (question = '') or confirm(question) then searcherAccess.orderConfirmedAsync(book);
end;

procedure TbookSearchFrm.searcherAccessPendingMessageCompleted(Sender: TObject);
begin
  screen.Cursor:=crDefault;
end;

procedure TbookSearchFrm.searcherAccessTakePendingMessage(sender: TObject; book: TBook; pendingMessage: TPendingMessage);
var
  i: Integer;
  sl: TStringList;
begin
  screen.Cursor:=crDefault;
  case pendingMessage.kind of
    pmkChoose: begin
      sl := TStringList.Create;
      for i :=  0 to high(pendingMessage.options) do
        sl.Add(pendingMessage.options[i]);
      i := InputList('VideLibri', pendingMessage.caption, sl );
      sl.free;
      screen.Cursor:=crHourGlass;

      searcherAccess.completePendingMessage(book, pendingMessage, i);
    end;
    pmkConfirm: begin
      searcherAccess.completePendingMessage(book, pendingMessage, ifthen(confirm(pendingMessage.caption), 1, 0));
    end;
  end;
end;

procedure TbookSearchFrm.searcherAccessSearchComplete(sender: TObject; firstPage, nextPageAvailable: boolean);
begin
  if sender <> searcherAccess then exit;
  if searcherAccess.searcher = nil then exit;

  bookList.BeginUpdate;
  if firstPage then bookList.Clear;
  self.nextPageAvailable := nextPageAvailable;;

  searcherAccess.beginResultReading;
  bookList.addBookList(searcherAccess.searcher.SearchResult);
  if (bookList.Items.Count = searcherAccess.searcher.SearchResultCount) or (searcherAccess.searcher.SearchResultCount = 0) then
    StatusBar1.Panels[SB_PANEL_FOUND_COUNT].text:=Format(rsCount, [IntToStr(bookList.Items.Count)])
  else
    StatusBar1.Panels[SB_PANEL_FOUND_COUNT].text:=Format(rsCountSelected, [bookList.Items.Count, searcherAccess.searcher.SearchResultCount]
      );
  searcherAccess.endResultReading;

  bookList.endupdate;

  if (bookList.TopItemVisualIndex + bookList.VisibleRowCount > bookList.Items.Count) and (nextPageAvailable) then begin
    searcherAccess.searchNextAsync;
    StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsLoadingNextPage;
  end else begin
    if nextPageAvailable then
      StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsSearchPartiallyComplete
    else
      StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsSearchComplete;
    autoSearchPhase:=aspSearched;
  end;

  screen.Cursor:=crDefault;


end;

procedure TbookSearchFrm.searchTitleChange(Sender: TObject);
begin

end;

procedure TbookSearchFrm.FormDestroy(Sender: TObject);
begin
  bookList.free;
  detaillist.free;
  searcherAccess.free;
  newSearcherAccess.free;
  locations.searchTemplates.free;
  locations.locations.Free;
  locations.regions.Free;
  selectedLibrariesPerLocation.free;
end;

procedure TbookSearchFrm.Image1Click(Sender: TObject);
begin

end;
procedure TbookSearchFrm.linkLabelDigibibClick(Sender: TObject);
var site: string;
begin
  if displayedBook=nil then begin
    ShowMessage(rsNoSelection);
    exit;
  end;

  site:=(sender as tlabel).Caption;
  if pos('digibib',LowerCase(site))>0 then begin
    site:=getProperty('digibib-url',displayedBook.additional);
  end else if (pos('katalog',LowerCase(site))>0) or (pos('bücherei',LowerCase(site))>0) then begin
    site:=getProperty('home-url',displayedBook.additional);
  end else if pos('amazon',LowerCase(site))>0 then begin
    site:=getProperty('amazon-url',displayedBook.additional);
  end else  if pos('buchhandel',LowerCase(site))>0 then begin
    site:=getProperty('buchhandel-url',displayedBook.additional);
    if site = '' then
     site:='http://www.buchhandel.de/default.aspx?strframe=titelsuche&caller=vlbPublic&func=DirectIsbnSearch&isbn='+displayedBook.getNormalizedISBN(true,13)+'&nSiteId=11';
  end else if pos('google',LowerCase(site))>0 then begin
    site:='http://www.google.de/search?q=%22'+displayedBook.title+'%22 %22'+displayedBook.author+'%22&ie=utf-8'
  end else begin
    ShowMessage('Gewünschte Seite nicht erkannt (wahrscheinlich Programmierfehler)');
    exit;
  end;
  
  if site='' then begin
    ShowMessage(rsNoLinkKnown);
    exit;
  end;
  if logging then log('Open page: '+site);
  OpenURL(site);
end;

procedure TbookSearchFrm.optionPanelClick(Sender: TObject);
begin

end;

procedure TbookSearchFrm.searcherAccessDetailsComplete(sender: TObject;
  book: TBook);
begin
  if sender <> searcherAccess then exit;
  if (displayDetails() < 2) and (displayImage.Checked) then begin
    searcherAccess.imageAsyncSave(displayedBook);
    StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:=rsSearchingCover;
  end else begin
    StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:='';
    screen.Cursor:=crDefault;
    autoSearchPhase:=aspSearchedDetails;
  end;
end;

procedure TbookSearchFrm.searcherAccessException(Sender: TObject);
begin
  if (sender <> searcherAccess) and (sender <> newSearcherAccess) then exit;
  mainForm.delayedCall.Enabled:=true;
end;

procedure TbookSearchFrm.searcherAccessImageComplete(sender: TObject;
  book: TBook);
begin
  if sender <> searcherAccess then exit;
  displayDetails();
  StatusBar1.Panels[SB_PANEL_SEARCH_STATUS].Text:='';
  autoSearchPhase:=aspSearchedDetails;
  screen.Cursor:=crDefault;
end;


procedure TbookSearchFrm.searchLocationSelect(Sender: TObject);
var
    i:longint;
    loki: Integer;
begin
  loki := locations.locations.IndexOf(searchLocation.Text);
  searchSelectionList.Items.Assign(TStringList(locations.locations.Objects[loki]));

  for i:=1 to min(length(selectedLibrariesPerLocation.Values[searchLocation.Text]),
                  searchSelectionList.Items.count) do
    searchSelectionList.Checked[i-1]:=selectedLibrariesPerLocation.Values[searchLocation.Text][i]='+';

  makeSearcherAccess;
  userConfig.WriteString('BookSearcher', currentLocationRegionConfig, searchLocation.Text);
end;

procedure TbookSearchFrm.searchSelectionListClickCheck(Sender: TObject);
var s:string;
    i:longint;
    oldState: String;
    last: LongInt;
    disallowMultiselect: Boolean;
begin
  oldState := selectedLibrariesPerLocation.Values[searchLocation.Text];
  disallowMultiselect := pos('digibib', searchLocation.Text) = 0;
  s:='';
  last := 0;
  for i:=0 to searchSelectionList.Items.count-1 do begin
    if searchSelectionList.Checked[i] then s+='+'
    else s+='-';
    if disallowMultiselect and searchSelectionList.Checked[i] and (i + 1 <= length(oldState)) and (oldState[i+1] = '+') then begin
      s[length(s)] := '-';
      last := i;
      searchSelectionList.Checked[i] := false;
    end;
  end;
  if (pos('+', s) = 0) and (last < searchSelectionList.Items.count) then begin
    searchSelectionList.Checked[last] := true;
    s[last+1] := '+';
  end;

  selectedLibrariesPerLocation.Values[searchLocation.Text]:=s;


  makeSearcherAccess;
end;

procedure TbookSearchFrm.makeSearcherAccess;
var
  first: Boolean;
  j: Integer;
  i: Integer;
  result: TLibrarySearcherAccess;
begin
  result:=TLibrarySearcherAccess.Create;
  result.OnSearchPageComplete:=@searcherAccessSearchComplete;
  result.OnDetailsComplete:=@searcherAccessDetailsComplete;
  result.OnOrderComplete:=@searcherAccessOrderComplete;
  result.OnOrderConfirm:=@searcherAccessOrderConfirm;
  result.OnTakePendingMessage:=@searcherAccessTakePendingMessage;
  result.OnPendingMessageCompleted:=@searcherAccessPendingMessageCompleted;
  result.OnImageComplete:=@searcherAccessImageComplete;
  result.OnException:=@searcherAccessException;
  result.OnConnected:=@searcherAccessConnected;
  if newSearcherAccess <> nil then newSearcherAccess.free;
  newSearcherAccess := result;

  i := locations.locations.IndexOf(searchLocation.Text);
  if i = -1 then
    exit;

  first := true;
  for j := 0 to searchSelectionList.Items.count - 1 do
    if searchSelectionList.Checked[j] then begin
      if first then begin
        result.newSearch( TSearchTarget((TStringList(locations.locations.Objects[i])).Objects[j]).template );
        result.searcher.clear;
        first := false;
      end;
      result.searcher.addLibrary(TSearchTarget((TStringList(locations.locations.Objects[i])).Objects[j]).lib);
    end;

  if first then begin
    if TStringList(locations.locations.Objects[i]).count = 0 then exit;
    result.newSearch( TSearchTarget((TStringList(locations.locations.Objects[i])).Objects[0]).template );
    result.searcher.clear;
    result.searcher.addLibrary(TSearchTarget((TStringList(locations.locations.Objects[i])).Objects[0]).lib);
    if searchSelectionList.Count > 0 then
      searchSelectionList.Checked[0] := true;
  end;

  result.connectAsync;
  updateBranches; //from cache
end;

function TbookSearchFrm.currentLocationRegionConfig: string;
var
  temp: TCaption;
  i: Integer;
begin
  temp := searchLocationRegion.Text;
  result := '';
  for i := 1 to length(temp) do if temp[i] in ['a'..'z','A'..'Z','0'..'9','-'] then result += temp[i];
  result := 'default-location-' + result;
end;


function TbookSearchFrm.displayDetails(book: TBook): longint;
var intern, empty, normal: TTreeListItems; //item lists
  procedure propAdd(n,v: string);
  begin
    if length(v)>1000 then begin
      if strEndsWith(n, '!') then v := copy(v, 1, 1000) + '..'
      else v:=Format(rsBytesHidden, [IntToStr(length(v))]);
    end;
    if not displayInternalProperties.Checked then begin
      if (n<>'')and(n[length(n)]='!')and(v<>'') then
        detaillist.items.add((copy(n,1,length(n)-1))).RecordItems.Add((v))
    end else begin
      if (n<>'')and(n[length(n)]='!')and(v<>'') then begin
        if normal=nil then normal:=detaillist.Items.Add(rsPropertiesNormal).SubItems;
        normal.add((copy(n,1,length(n)-1))).RecordItems.Add((v))
      end else if (n<>'') and (n[length(n)]<>'!') then begin
        if intern=nil then intern:=detaillist.Items.Add(rsPropertiesInternal).SubItems;
        intern.add((n)).RecordItems.Add((v));
      end else begin
        if empty=nil then empty:=detaillist.Items.Add(rsPropertiesEmpty).SubItems;
        empty.add((n)).RecordItems.Add((v))
      end;


    end;
  end;
  procedure propAddForce(n,v: string);
  begin
    propAdd(n+'!',v);
  end;

const holdingColumns: array[0..6] of string = (
  'id',
  'category',
  'author',
  'title',
  'year',
  'libraryBranch',
  'status'
);

var i:longint;
    tempStream: TStringAsMemoryStream;
    ext: String;
    j, orderableHolding: Integer;
    showColumn: Boolean;
    tempBook: TBook;
begin
  if book=nil then
    if bookList.Selected=nil then book:=displayedBook
    else book:=tbook(bookList.Selected.data.obj);
  if (book=nil) then exit;
  intern:=nil;
  empty:=nil;
  normal:=nil;
  displayedBook:=book;
  Result:=0;
  if searcherAccess <> nil then searcherAccess.beginBookReading;
  try
    detaillist.BeginUpdate;
    detaillist.items.clear;
    propAddForce(rsBookPropertyID,book.id);
    propAddForce(rsBookPropertyCategory,book.category);
    propAddForce(rsBookPropertyAuthor,book.author);
    propAddForce(rsBookPropertyTitle,book.title);
    propAddForce(rsBookPropertyYear,book.year);
    propAddForce(rsBookPropertyISBN,book.isbn);
    if getProperty('publisher', book.additional) <> '' then propAddForce(rsBookPropertyPublisher, getProperty('publisher', book.additional));
    if getProperty('location', book.additional) <> '' then propAddForce(ifthen(book.lend, rsBookPropertyLocationLend, rsBookPropertyLocationSearch), getProperty('location', book.additional));
    if book.owningAccount<>nil then begin
      propAddForce(rsBookPropertyIssueDate, DateToPrettyStr(book.issueDate));
      propAddForce(rsBookPropertyLimitDate, DateToPrettyStr(book.dueDate));
      propAddForce(rsBookPropertyStatus, BookStatusToStr(book,true));
      propAdd(rsBookPropertyFirstTime, DateToPrettyStr(book.firstExistsDate));
      propAdd(rsBookPropertyLastTime, DateToPrettyStr(book.lastExistsDate));
      if book.renewCount > 0 then propAddForce(rsBookPropertyRenewCount, IntToStr(book.renewCount));
    end;
    for i:=0 to high(book.additional) do
      propAdd(book.additional[i].name,book.additional[i].value);
    detaillist.EndUpdate;

    Image1.Picture.Clear;
    Image1.AutoSize:=false;
    Image1.Width:=1;
    if displayImage.Checked and (length(getProperty('image',book.additional))>50) then begin
      try
        tempStream:=TStringAsMemoryStream.Create(getProperty('image',book.additional));
        try
          ext := getProperty('image-content-type',book.additional);
          if striContains(ext, 'image/jpeg') or striContains(ext, 'image/jpg') then ext := '.jpg'
          else if striContains(ext, 'image/png') then ext := '.png'
          else if striContains(ext, 'image/gif') then ext := '.gif'
          else ext := ExtractFileExt(getProperty('image-url',book.additional));
          if (ext = '') or (ext = '.') then image1.Picture.LoadFromStream(tempStream)
          else image1.Picture.LoadFromStreamWithFileExt(tempStream, ext);
          Image1.width:=min(image1.Picture.Width, Image1.Picture.Width * image1.Height div max(1,image1.Picture.Height));
        finally
          tempStream.free;
        end;
      except
        //sometimes the image is just garbage
      end;
    end;
    
    if getProperty('details-searched',book.additional) <> 'true' then Result:=0
    else if getProperty('image-searched',book.additional) <> 'true' then result:=1
    else result:=2;


    linkLabelDigibib.Enabled := getProperty('digibib-url', book.additional) <> '';
    linkLabelBib.Enabled := getProperty('home-url', book.additional) <> '';
    if getProperty('amazon-url', book.additional) <> '' then begin
      linkLabelAmazon.Caption := 'amazon.de';
      linkLabelAmazon.Enabled := true;
    end else if (getProperty('buchhandel-url', book.additional) <> '') or (strContains(getProperty('image-real-url', book.additional), 'vlb.de')) then begin
      linkLabelAmazon.Caption := 'buchhandel.de';
      linkLabelAmazon.Enabled := true;
    end else linkLabelAmazon.Enabled := false;

    LabelOrder.Enabled:=(getProperty( 'orderable', book.additional) <> '') and (getProperty('orderable', book.additional) <> '0') and (getProperty('orderable', book.additional) <> 'false');
    if book.holdings = nil then begin
      holdingsPanel.Visible := false;
      holdingsSplitter.Visible := false;
      LabelOrder.Caption := book.getPropertyAdditional('orderTitle', rsRequestOrder);
    end else begin
      holdings.BeginUpdate;
      holdings.clear;
      holdings.ColumnsClear;
      for i := 0 to high(holdingColumns) do begin
        showColumn := false;
        for j := 0 to book.holdings.Count - 1 do
          if book.holdings[j].getProperty(holdingColumns[i]) <> '' then begin
            showColumn := true;
            break;
          end;
        if showColumn then holdings.addColumn(holdingColumns[i]);
      end;
      for i := 0 to book.holdings.Count-1 do begin
        tempBook := book.holdings[i];
        for j:=0 to high(tempBook.additional) do
          if strEndsWith(tempBook.additional[j].name,'!')
             and (holdings.getPropertyColumnIndex(tempBook.additional[j].name) = -1) then
            holdings.addColumn(tempBook.additional[j].name);
      end;
      showColumn := false;
      for i := 0 to book.holdings.Count - 1 do
        if book.holdings[i].dueDate <> 0 then begin
          showColumn:=true;
          break;
        end;
      if showColumn then holdings.addColumn('dueDate');
      holdings.addBookList(book.holdings);
      holdings.ColumnsAutoSize;

      orderableHolding := -1;
      for i := 0 to book.holdings.Count - 1 do
        if (orderableHolding = -1) and (book.holdings[i].getProperty('orderable') <> 'false') then
          orderableHolding := i;
      holdingsPanel.Visible := True;
      holdingsSplitter.Visible := True;
      if orderableHolding >= 0 then
        holdings.Selected := holdings.Items[orderableHolding];
      holdings.EndUpdate;
    end;

  finally
    if searcherAccess <> nil then searcherAccess.endBookReading;
  end;
end;

procedure TbookSearchFrm.detaillistMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  detaillistLastClickedRecordItem := (sender as TTreeListView).GetRecordItemAtPos(x,y);
end;

procedure TbookSearchFrm.bookListHoldingsSelect(sender: TObject; item: TTreeListItem);
var
  book: TBook;
  cmdtitle: String;
begin
  if (item = nil) or not item.Selected then exit;
  book:=tbook(item.data.obj);
  if book = nil then exit;
  LabelOrder.Enabled := book.getProperty('orderable') <> 'false';
  if not LabelOrder.Enabled and (book.owningBook <> nil)  then
    LabelOrder.Enabled:=(getProperty( 'orderable', book.owningBook.additional) <> '') and (getProperty('orderable', book.owningBook.additional) <> '0') and (getProperty('orderable', book.owningBook.additional) <> 'false');
  cmdtitle := book.getPropertyAdditional('orderTitle', '');
  if (cmdtitle = '') and (book.owningBook <> nil) then
    cmdtitle := book.owningBook.getPropertyAdditional('orderTitle', '');
  if cmdtitle = '' then cmdtitle:=rsRequestOrder;
  LabelOrder.Caption := cmdtitle;
end;

function TbookSearchFrm.cloneDisplayedBook: TBook;
begin
  if searcherAccess = nil then exit;
  searcherAccess.beginBookReading;
  result := displayedBook.clone;
  searcherAccess.endBookReading;
end;

procedure TbookSearchFrm.selectBookToReSearch(book: TBook);
  function selectLibrary(location: string; lib: TLibrary): boolean;
  var
    state: String;
    i: Integer;
  begin
    if searchLocation.Items.IndexOf(location) < 0 then exit(false);
    searchLocation.Text:=location;
    searchLocationSelect(self);

    state := '';
    for i:=0 to searchSelectionList.items.Count-1 do begin
      searchSelectionList.Checked[i]:=TSearchTarget(searchSelectionList.items.Objects[i]).lib=lib;
      if searchSelectionList.Checked[i] then state += '+'
      else state += '-';
    end;
    selectedLibrariesPerLocation.Values[searchLocation.Text]:=state;

    result := pos('+', state) > 0;

    makeSearcherAccess;
  end;

var i,rp:longint;
    s: string;
    accId: Integer;
    lib: TLibrary;
begin
  researchedBook := nil;
  if book = nil then
    exit;

  displayDetails(book);
  searchAuthor.Text:=book.author;
  s:=book.title;
  for i:=length(s) downto 1 do
    if s[i] in [' ',',','.'] then s[i]:=' '
    else break;
  s:=trim(s);
  while striendswith(s,'Aufl') or striendswith(s,'Ausg') or striendswith(s,'Nachdr')
        or striendswith(s,'print') or striendswith(s,' ed') or striendswith(s,' pr') do begin
    rp:=0;
    for i:=length(s) downto 2 do
      if (s[i] = '.') and (s[i-1] in ['0'..'9']) then begin
        rp:=i-1;
        break;
      end;
    delete(s,rp,length(s)-rp+1);
    for i:=length(s) downto 1 do
      if s[i] in [' ',',','.'] then s[i]:=' '
      else break;
    s:=trim(s);
    if rp=0 then break;
  end;


  
  searchTitle.Text:=trim(s)+'*';
  if book.owningAccount is TCustomAccountAccess then begin
    lib := TCustomAccountAccess(book.owningAccount).getLibrary();
    if not selectLibrary(lib.prettyLocation, lib) then
      selectLibrary(lib.prettyLocation+ ' (digibib)', lib);

    accId := accounts.IndexOfObject(book.owningAccount);
    if (accId >= 0) and (accId < saveToAccountMenu.Items.Count) then begin
      changeDefaultSaveToAccount(saveToAccountMenu.Items[accId]);
      researchedBook := book;
    end;
    if (accId >= 0) and (accId < orderForAccountMenu.Items.Count) then begin
      changeDefaultOrderForAccount(orderForAccountMenu.Items[accId]);
    end;
  end;


end;

procedure TbookSearchFrm.loadDefaults;
  procedure loadComboBoxItems(cb: TComboBox);
  begin
    cb.Items.Text:=StringReplace(
                      StringReplace(
                         userConfig.ReadString('BookSearcher','History'+cb.Name,''),
                         '\n',
                         LineEnding,
                         [rfReplaceAll]),
                      '\\','\',[rfReplaceAll]);
  end;
var i:longint;
  temp: String;
begin
  locations := getSearchableLocations;

  searchLocation.Items.Clear;
  for i := 0 to locations.locations.count - 1 do
    searchLocation.Items.add(locations.locations[i]);

  searchLocationRegion.Items.Clear;
  for i := 0 to locations.regions.count - 1 do
    searchLocationRegion.Items.add(locations.regions[i]);


  for i:=0 to locations.locations.count-1 do
    selectedLibrariesPerLocation.Values[locations.locations[i]]:=userConfig.ReadString('BookSearcher','selection-'+locations.locations[i],'+--');

  temp := userConfig.ReadString('BookSearcher', 'default-region', '');
  if locations.regions.IndexOf(temp) >= 0 then searchLocationRegion.Text:=temp
  else searchLocationRegion.Text:=searchLocationRegion.items[0];
  searchLocationRegionSelect(self);

  loadComboBoxItems(searchAuthor);
  loadComboBoxItems(searchTitle);
  loadComboBoxItems(searchKeywords);
  loadComboBoxItems(searchYear);
  loadComboBoxItems(searchISBN);
  saveToDefaultAccountID := userConfig.ReadString('BookSearcher','default-save-to', '');
  if accounts.IndexOf(saveToDefaultAccountID) >= 0 then
    LabelSaveTo.Caption := rsIn + ' \/ '+ accounts[accounts.IndexOf(saveToDefaultAccountID)].prettyName;
  orderForDefaultAccountID := userConfig.ReadString('BookSearcher','default-order-for', '');
  if accounts.IndexOf(orderForDefaultAccountID) >= 0 then
    LabelOrderFor.Caption := rsFor + ' \/ '+ accounts[accounts.IndexOf(orderForDefaultAccountID)].prettyName;
end;

procedure TbookSearchFrm.saveDefaults;
  procedure saveComboBoxItems(cb: TComboBox);
  begin
    userConfig.WriteString('BookSearcher','History'+cb.Name,
       StringReplace(
         StringReplace(cb.Items.Text,'\','\\',[rfReplaceAll]),
         LineEnding,'\n',[rfReplaceAll]));
  end;
var i:longint;
begin
  for i:=0 to selectedLibrariesPerLocation.Count-1 do
    userConfig.WriteString('BookSearcher','selection-'+selectedLibrariesPerLocation.Names[i],selectedLibrariesPerLocation.ValueFromIndex[i]);
  saveComboBoxItems(searchAuthor);
  saveComboBoxItems(searchTitle );
  saveComboBoxItems(searchKeywords);
  saveComboBoxItems(searchYear);
  saveComboBoxItems(searchISBN);
  userConfig.WriteString('BookSearcher','default-save-to', saveToDefaultAccountID);
  userConfig.WriteString('BookSearcher','default-order-for', orderForDefaultAccountID);
  userConfig.WriteString('BookSearcher', 'default-region', searchLocationRegion.Text);
  userConfig.WriteString('BookSearcher', currentLocationRegionConfig, searchLocation.Text);
end;

procedure TbookSearchFrm.changeDefaultSaveToAccount(sender: tobject);

begin
  if not (sender is TMenuItem) then exit;
  if tmenuitem(sender).Tag <= 1 then tmenuitem(sender).Tag := 1;
  if tmenuitem(sender).Tag > accounts.count then tmenuitem(sender).Tag := accounts.count;
  saveToDefaultAccountID := accounts.Strings[tmenuitem(sender).Tag-1];

  LabelSaveTo.Caption := rsIn + ' \/ '+ TMenuItem(sender).Caption;

  tmenuitem(sender).Checked:=true;
end;

procedure TbookSearchFrm.changeDefaultOrderForAccount(sender: tobject);

begin
  if not (sender is TMenuItem) then exit;
  if tmenuitem(sender).Tag <= 1 then tmenuitem(sender).Tag := 1;
  if tmenuitem(sender).Tag > accounts.count then tmenuitem(sender).Tag := accounts.count;

  orderForDefaultAccountID := accounts.Strings[tmenuitem(sender).Tag-1];
  LabelOrderFor.Caption := rsFor + ' \/ '+ TMenuItem(sender).Caption;

  tmenuitem(sender).Checked:=true;
end;

initialization
  {$I bookSearchForm.lrs}
end.


