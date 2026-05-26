' ============================================================
' Create-Sequence-Diagram.vbs  — EA 15.2
' Orden correcto via SequenceNo en DiagramLink
' ============================================================

Const LIFELINE_W   = 90
Const FIRST_X      = 100
Const X_GAP        = 180
Const FIRST_MSG_Y  = 160
Const Y_GAP        = 36
Const ALT_LABEL_H  = 22
Const ALT_SEP_H    = 18
Const ALT_END_H    = 10
Const FRAG_LEFT    = -600
Const FRAG_TOP     = 50
Const FRAG_WIDTH   = 550
Const FRAG_HEIGHT  = 70
Const FRAG_GAP     = 90

Sub RunPlantUMLScript()
    Dim eaApp, repo, pkg, diag, script, diagName, fso, filePath, fileObj
    Set eaApp = GetObject(, "EA.App")
    Set repo  = eaApp.Repository
    Set pkg = repo.GetTreeSelectedPackage()
    If pkg Is Nothing Then
        MsgBox "Selecciona un paquete en el Project Browser.", vbExclamation
        Exit Sub
    End If
    filePath = InputBox("Ruta completa del archivo .txt con el PlantUML:" & Chr(10) & Chr(10) & "Ej: C:\Users\Usuario\Downloads\DSS_CUN01_plantuml.txt", "PlantUML -> EA")
    If Trim(filePath) = "" Then Exit Sub
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FileExists(Trim(filePath)) Then
        MsgBox "Archivo no encontrado: " & filePath, vbExclamation
        Exit Sub
    End If
    Set fileObj = fso.OpenTextFile(Trim(filePath), 1, False, -2)
    script = fileObj.ReadAll()
    fileObj.Close
    diagName = ExtractTitle(script)
    If diagName = "" Then diagName = fso.GetBaseName(filePath)
    Set diag = pkg.Diagrams.AddNew(diagName, "Sequence")
    diag.Update
    Call BuildDiagram(repo, pkg, diag, script)
End Sub

Function ExtractTitle(script)
    Dim lines, i, s
    ExtractTitle = ""
    s = Replace(Replace(script, Chr(13) & Chr(10), Chr(10)), Chr(13), Chr(10))
    lines = Split(s, Chr(10))
    For i = 0 To UBound(lines)
        If Left(LCase(Trim(lines(i))), 6) = "title " Then
            ExtractTitle = Trim(Mid(lines(i), 7)) : Exit Function
        End If
    Next
End Function

Sub BuildDiagram(repo, pkg, diag, script)
    Dim lines, i, j
    Dim raw, lo, kw, stereo, rest, pn, pa, asPos, namePart, found
    Dim newEl, dob, lx, cx, msgY
    Dim dobID(99), pName(99), pAlias(99), pType(99), pElem(99)
    Dim pCount : pCount = 0
    Dim altDepth : altDepth = 0
    Dim altStartY(10), altLabel(10)
    Dim evType(200), evY1(200), evSrc(200), evDst(200)
    Dim evMsg(200), evArrow(200), evLabel(200)
    Dim evCount : evCount = 0
    Dim firstActor : firstActor = True

    script = Replace(Replace(script, Chr(13) & Chr(10), Chr(10)), Chr(13), Chr(10))
    lines  = Split(script, Chr(10))

    ' ---- PASADA 1: participantes ----
    For i = 0 To UBound(lines)
        raw = Trim(lines(i)) : lo = LCase(raw) : kw = "" : stereo = ""
        If Left(lo,6) = "actor " Then
            kw = "actor"
            If firstActor Then
                stereo = "Actor"
                firstActor = False
            Else
                stereo = "Class"
            End If
        End If
        If Left(lo,9) ="boundary "    Then kw="boundary":   stereo="Boundary"
        If Left(lo,8) ="control "     Then kw="control":    stereo="Class"
        If Left(lo,7) ="entity "      Then kw="entity":     stereo="Class"
        If Left(lo,9) ="database "    Then kw="database":   stereo="Class"
        If Left(lo,12)="participant " Then kw="participant": stereo="Class"
        If kw <> "" Then
            rest = Trim(Mid(raw,Len(kw)+2)) : asPos = InStr(LCase(rest)," as ")
            If asPos > 0 Then
                namePart = Trim(Left(rest,asPos-1)) : pa = Trim(Mid(rest,asPos+4))
                If Left(namePart,1)=Chr(34) Then pn=Mid(namePart,2,Len(namePart)-2) Else pn=namePart
            Else
                If Left(rest,1)=Chr(34) Then pn=Mid(rest,2,InStr(2,rest,Chr(34))-2) Else pn=rest
                pa = pn
            End If
            found = False
            For j = 0 To pCount-1
                If pName(j)=pn Or pAlias(j)=pa Then found=True
            Next
            If Not found Then
                pName(pCount)=CleanText(pn) : pAlias(pCount)=pa : pType(pCount)=stereo : pCount=pCount+1
            End If
        End If
    Next
    If pCount = 0 Then MsgBox "No se encontraron participantes.", vbExclamation : Exit Sub

    ' ---- PASADA 2: pre-calcular eventos con Y ----
    msgY = FIRST_MSG_Y : altDepth = 0
    For i = 0 To UBound(lines)
        raw = Trim(lines(i)) : lo = LCase(raw)
        If raw = "" Then
        ElseIf Left(lo,9) ="@startuml"    Then
        ElseIf Left(lo,7) ="@enduml"      Then
        ElseIf Left(lo,6) ="title "       Then
        ElseIf Left(lo,9) ="activate "    Then
        ElseIf Left(lo,11)="deactivate "  Then
        ElseIf Left(lo,9) ="note over "   Then
        ElseIf Left(lo,6) ="actor "       Then
        ElseIf Left(lo,9) ="boundary "    Then
        ElseIf Left(lo,8) ="control "     Then
        ElseIf Left(lo,7) ="entity "      Then
        ElseIf Left(lo,9) ="database "    Then
        ElseIf Left(lo,12)="participant " Then
        ElseIf Left(lo,3)="alt" And (Len(lo)=3 Or Mid(lo,4,1)=" " Or Mid(lo,4,1)="[") Then
            altStartY(altDepth)=msgY : altLabel(altDepth)=raw
            altDepth=altDepth+1 : msgY=msgY+ALT_LABEL_H
        ElseIf Left(lo,4)="else" And (Len(lo)=4 Or Mid(lo,5,1)=" " Or Mid(lo,5,1)="[") Then
            msgY=msgY+ALT_SEP_H
        ElseIf Left(lo,4)="loop" And (Len(lo)=4 Or Mid(lo,5,1)=" ") Then
            altStartY(altDepth)=msgY : altLabel(altDepth)=raw
            altDepth=altDepth+1 : msgY=msgY+ALT_LABEL_H
        ElseIf Left(lo,3)="opt" And (Len(lo)=3 Or Mid(lo,4,1)=" ") Then
            altStartY(altDepth)=msgY : altLabel(altDepth)=raw
            altDepth=altDepth+1 : msgY=msgY+ALT_LABEL_H
        ElseIf lo = "end" Then
            If altDepth > 0 Then
                altDepth=altDepth-1
                evType(evCount)=2 : evLabel(evCount)=CleanText(altLabel(altDepth))
                evCount=evCount+1
            End If
            msgY=msgY+ALT_END_H
        ElseIf Left(raw,1)="[" And InStr(raw,"]")>0 And InStr(raw,"->")<1 Then
        ElseIf InStr(raw,"->") > 0 Then
            Dim arrow : arrow=""
            If InStr(raw,"-->>")>0 Then arrow="-->>"
            If arrow="" Then If InStr(raw,"->>")>0 Then arrow="->>"
            If arrow="" Then If InStr(raw,"-->")>0 Then arrow="-->"
            If arrow="" Then If InStr(raw,"->")>0  Then arrow="->"
            If arrow <> "" Then
                Dim ap : ap=InStr(raw,arrow)
                Dim sr : sr=Trim(Left(raw,ap-1))
                Dim aa : aa=Trim(Mid(raw,ap+Len(arrow)))
                Dim cp : cp=InStr(aa,":")
                Dim dr, mn
                If cp>0 Then dr=Trim(Left(aa,cp-1)) : mn=CleanText(Trim(Mid(aa,cp+1))) Else dr=Trim(aa) : mn=""
                evType(evCount)=1 : evY1(evCount)=msgY
                evSrc(evCount)=ResolveAlias(sr,pName,pAlias,pCount)
                evDst(evCount)=ResolveAlias(dr,pName,pAlias,pCount)
                evMsg(evCount)=mn : evArrow(evCount)=arrow
                evCount=evCount+1 : msgY=msgY+Y_GAP
            End If
        End If
    Next
    Dim totalHeight : totalHeight = msgY+60

    ' ---- CREAR LIFELINES en orden NORMAL (izq a der) ----
    cx = FIRST_X
    For i = 0 To pCount-1
        Set newEl = pkg.Elements.AddNew(pName(i),"Class")
        newEl.Stereotype=pType(i) : newEl.Update
        lx = cx-(LIFELINE_W\2)
        Set dob = diag.DiagramObjects.AddNew("","")
        dob.ElementID=newEl.ElementID : dob.left=lx : dob.top=0
        dob.right=lx+LIFELINE_W : dob.bottom=totalHeight : dob.Update
        Set pElem(i)=newEl : dobID(i)=dob.InstanceID
        cx=cx+X_GAP
    Next
    diag.Update

    ' ---- NOTA HTTPS/TLS ----
    Dim noteEl, noteDob
    Set noteEl = pkg.Elements.AddNew("","Note")
    noteEl.Notes = "Toda comunicacion entre Psicologo y GUI viaja sobre HTTPS/TLS"
    noteEl.Update
    Set noteDob = diag.DiagramObjects.AddNew("","")
    noteDob.ElementID=noteEl.ElementID
    noteDob.left=FIRST_X-(LIFELINE_W\2) : noteDob.top=10
    noteDob.right=FIRST_X+X_GAP+(LIFELINE_W\2) : noteDob.bottom=52 : noteDob.Update

    ' ---- CREAR FRAGMENTOS en paquete separado ----
    Dim fragPkg
    Set fragPkg = pkg.Packages.AddNew("_ALT_Fragments","")
    fragPkg.Update
    Dim fragCount : fragCount = 0
    For i = 0 To evCount-1
        If evType(i) = 2 Then
            Dim fragEl, fragDob
            Dim fragTop : fragTop = FRAG_TOP + fragCount*FRAG_GAP
            Set fragEl = fragPkg.Elements.AddNew(evLabel(i),"InteractionFragment")
            fragEl.Update
            Set fragDob = diag.DiagramObjects.AddNew("","")
            fragDob.ElementID=fragEl.ElementID
            fragDob.left=FRAG_LEFT : fragDob.top=fragTop
            fragDob.right=FRAG_LEFT+FRAG_WIDTH : fragDob.bottom=fragTop+FRAG_HEIGHT
            fragDob.Update
            fragCount=fragCount+1
        End If
    Next
    fragPkg.Update

    ' ---- CREAR MENSAJES en orden NORMAL con SequenceNo ----
    ' SequenceNo fuerza el orden visual en EA independientemente
    ' del orden de insercion en la base de datos
    Dim seqNo : seqNo = 1
    For i = 0 To evCount-1
        If evType(i) = 1 Then
            Dim si : si=FindIdx(evSrc(i),pName,pAlias,pCount)
            Dim di : di=FindIdx(evDst(i),pName,pAlias,pCount)
            If si >= 0 And di >= 0 Then
                Dim se : Set se=pElem(si)
                Dim de : Set de=pElem(di)
                Dim mt : mt="Synchronous"
                If evArrow(i)="-->" Or evArrow(i)="-->>" Then mt="Return"
                If evArrow(i)="->>" Then mt="Asynchronous"

                ' Crear conector con SequenceNo para orden correcto
                Dim cn : Set cn=se.Connectors.AddNew(evMsg(i),"Sequence")
                cn.Stereotype  = mt
                cn.ClientID    = se.ElementID
                cn.SupplierID  = de.ElementID
                cn.SequenceNo  = seqNo
                cn.Update

                Dim lk : Set lk=diag.DiagramLinks.AddNew("","")
                lk.ConnectorID = cn.ConnectorID

                Dim gm
                If si=di Then
                    gm="EDGE=1;$LLT="&dobID(si)&";$LLB="&dobID(si)&";SX=0;SY="&evY1(i)&";EX=30;EY="&(evY1(i)+22)&";EDGETYPE=Bezier;"
                Else
                    gm="EDGE=1;$LLT="&dobID(si)&";$LLB="&dobID(di)&";SX=0;SY="&evY1(i)&";EX=0;EY="&evY1(i)&";"
                End If
                lk.Geometry = gm
                lk.Update
                seqNo = seqNo + 1
            End If
        End If
    Next

    diag.Update
    repo.ReloadPackage(pkg.PackageID)
    repo.OpenDiagram(diag.DiagramID)
    MsgBox "Diagrama generado!" & Chr(10) & Chr(10) & _
           "Participantes: " & pCount & Chr(10) & _
           "Mensajes: " & (seqNo-1) & Chr(10) & Chr(10) & _
           "Los " & fragCount & " bloques ALT estan a la izquierda." & Chr(10) & _
           "Arrastralos a su posicion correspondiente.", vbInformation
End Sub

' ============================================================
' Limpia el texto: elimina \n del PlantUML y caracteres especiales
' ============================================================
Function CleanText(s)
    Dim r
    r = s
    ' Eliminar saltos de linea de PlantUML (\n literal y real)
    r = Replace(r, "\n", " ")
    r = Replace(r, Chr(10), " ")
    r = Replace(r, Chr(13), " ")
    ' Eliminar caracteres especiales no ASCII (acentos, etc)
    Dim result
    result = ""
    Dim k
    Dim c
    For k = 1 To Len(r)
        c = Asc(Mid(r, k, 1))
        ' Mantener solo ASCII imprimible (32-126)
        If c >= 32 And c <= 126 Then
            result = result & Mid(r, k, 1)
        End If
    Next
    ' Colapsar espacios multiples
    Do While InStr(result, "  ") > 0
        result = Replace(result, "  ", " ")
    Loop
    CleanText = Trim(result)
End Function

Function ResolveAlias(token, pName, pAlias, pCount)
    Dim k
    For k=0 To pCount-1
        If LCase(pAlias(k))=LCase(token) Then ResolveAlias=pName(k) : Exit Function
    Next
    ResolveAlias=token
End Function

Function FindIdx(token, pName, pAlias, pCount)
    Dim k : FindIdx=-1
    For k=0 To pCount-1
        If LCase(pName(k)) =LCase(token) Then FindIdx=k : Exit Function
        If LCase(pAlias(k))=LCase(token) Then FindIdx=k : Exit Function
    Next
End Function

RunPlantUMLScript
