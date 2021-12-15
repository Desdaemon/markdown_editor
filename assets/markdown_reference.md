# Markdown Cheat Sheet
## Headings
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

```md
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

## Paragraphs

This is a sentence in paragraph A.
This is also a sentence in paragraph A.

This is not, however.

```md
This is a sentence in paragraph A.
This is also a sentence in paragraph A.

This is not, however.
```

## Formatting

| Content                | Syntax                   |
| ---------------------- | ------------------------ |
| **Bold**               | `**Bold**`               |
| _Italic_               | `*Italic*`               |
| **Bold then _Italic_** | `**Bold then *Italic***` |
| ~~Removed~~            | `~~Removed~~`            |

## Lists

### Unordered List

- Item 1
- Item 2
- [ ] Item 3 with checkbox
- [x] Item 4 with checked checkbox

```md
- Item 1
- Item 2
- [ ] Item 3 with checkbox
- [x] Item 4 with checked checkbox
```

### Ordered List

1. Une
2. Deux
3. Trois
4. Quatre

```md
1. Une
2. Deux
3. Trois
4. Quatre
```

## Tables

| ID     | Name       | Gender |   Amount |
| ------ | :--------- | :----: | -------: |
| 000001 | Bob Ross   |  Male  |  $123.00 |
| 035002 | Mike Tyson |  Male  |    $5.00 |
| 123456 | Inkling    | Female | $5554.12 |

```md
| ID     | Name       | Gender |   Amount |
| ------ | :--------- | :----: | -------: |
| 000001 | Bob Ross   |  Male  |  $123.00 |
| 035002 | Mike Tyson |  Male  |    $5.00 |
| 123456 | Inkling    | Female | $5554.12 |
```

## Blockquotes

> "Insert wise man quote here" - Anonymous, 2XXX

```md
> "Insert wise man quote here" - Anonymous, 2XXX
```

## Code blocks

### Code spans

`doStuff()` is a method.

```md
`doStuff()` is a method.
```

### Fenced code blocks

```python
if __name__ == "__main__":
    do_stuff()
```

    ```python
    if __name__ == "__main__":
       do_stuff()
    ```

### Indented code blocks

    Indented lines are treated as code blocks.

This is not, however.

```md
    Indented lines are treated as code blocks.

This is not, however.
```

## Comments

```md
<!-- An HTML comment that is invisible in the final output -->
```

## Links

### Autolinks

https://www.google.com

<john@gmail.com>

```md
https://www.google.com

<john@gmail.com>
```

### Text Links

[English Wikipedia](https://en.wikipedia.org)

```md
[English Wikipedia](https://en.wikipedia.org)
```

### Picture Links

[![Link to Penguin](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg/160px-South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg)](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg/160px-South_Shetland-2016-Deception_Island%E2%80%93Chinstrap_penguin_%28Pygoscelis_antarctica%29_04.jpg)

```md
[![Link to Penguin](...)](...)
```

## Emojis

:smile:

# TeX Cheat Sheet

## Inline Math and Math Block

The result of $1+1$ is $2$.
$$a^2+b^2=c^2$$

```md
The result of $1+1$ is $2$.
$$a^2+b^2=c^2$$
```

## Accents

| Content        | Syntax         | Content                    | Syntax                     |
| -------------- | -------------- | -------------------------- | -------------------------- |
| $a'$           | `a'`           | $\tilde{a}$                | `\tilde{a}`                |
| $a''$          | `a''`          | $\widetilde{ac}$           | `\widetilde{ac}`           |
| $a^{\prime}$   | `a^{\prime}`   | $\utilde{AB}$              | `\utilde{AB}`              |
| $\acute{a}$    | `\acute{a}`    | $\vec{F}$                  | `\vec{F}`                  |
| $\bar{y}$      | `\bar{y}`      | $\overleftarrow{AB}$       | `\overleftarrow{AB}`       |
| $\breve{a}$    | `\breve{a}`    | $\underleftarrow{AB}$      | `\underleftarrow{AB}`      |
| $\check{a}$    | `\check{a}`    | $\overleftharpoon{ac}$     | `\overleftharpoon{ac}`     |
| $\dot{a}$      | `\dot{a}`      | $\overleftrightarrow{AB}$  | `\overleftrightarrow{AB}`  |
| $\ddot{a}$     | `\ddot{a}`     | $\underleftrightarrow{AB}$ | `\underleftrightarrow{AB}` |
| $\grave{a}$    | `\grave{a}`    | $\overline{AB}$            | `\overline{AB}`            |
| $\hat{\theta}$ | `\hat{\theta}` | $\underline{AB}$           | `\underline{AB}`           |
| $\widehat{ac}$ | `\widehat{ac}` | $\widecheck{ac}$           | `\widecheck{ac}`           |

## Delimiters

| Content                  | Syntax                   | Content              | Syntax               |
| ------------------------ | ------------------------ | -------------------- | -------------------- |
| $\lparen\rparen$         | `\lparen\rparen`         | $\lgroup\rgroup$     | `\lgroup\rgroup`     |
| $\lbrack\rbrack$         | `\lbrack\rbrack`         | $\ulcorner\urcorner$ | `\ulcorner\urcorner` |
| $\lbrace\rbrace$         | `\lbrace\rbrace`         | $\llcorner\lrcorner$ | `\llcorner\lrcorner` |
| $\langle\rangle$         | `\langle\rangle`         | $\llbracket$         | `\llbracket`         |
| $\lang\rang$             | `\lang\rang`             | $\rrbracket$         | `\rrbracket`         |
| $\vert$                  | `\vert`                  | $\uparrow$           | `\uparrow`           |
| $\lvert\rvert$           | `\lvert\rvert`           | $\downarrow$         | `\downarrow`         |
| $\Vert$                  | `\Vert`                  | $\updownarrow$       | `\updownarrow`       |
| $\lVert\rVert$           | `\lVert\rVert`           | $\Uparrow$           | `\Uparrow`           |
| $\lt\gt$                 | `\lt\gt`                 | $\Downarrow$         | `\Downarrow`         |
| $\lceil\rceil$           | `\lceil\rceil`           | $\Updownarrow$       | `\Updownarrow`       |
| $\lfloor\rfloor$         | `\lfloor\rfloor`         | $\backslash$         | `\backslash`         |
| $\lmoustache\rmoustache$ | `\lmoustache\rmoustache` | $\lBrace\rBrace$     | `\lBrace\rBrace`     |

### Delimiter Sizing

$\left(\LARGE{AB}\right)$ `\left(\LARGE{AB}\right)`

$( \big( \Big( \bigg( \Bigg($ `( \big( \Big( \bigg( \Bigg(`

|          |         |          |          |          |
| -------- | ------- | -------- | -------- | -------- |
| `\left`  | `\big`  | `\bigl`  | `\bigm`  | `\bigr`  |
| `\right` | `\Big`  | `\Bigl`  | `\Bigm`  | `\Bigr`  |
| `\right` | `\bigg` | `\biggl` | `\biggm` | `\biggr` |
|          | `\Bigg` | `\Biggl` | `\Biggm` | `\Biggr` |

## Environments

_Usage_:

```t
\begin{environment}{options}
  ...
\end{environment}
```

For the alignment environments, `&` denotes an anchor position.

| Content                                                                   | Environment   |
| ------------------------------------------------------------------------- | ------------- |
| $\begin{matrix}a&b\\c&d\end{matrix}$                                      | `matrix`      |
| $\begin{array}{cc}a&b\\c&d\end{array}$                                    | `array`       |
| $\begin{pmatrix}a&b\\c&d\end{pmatrix}$                                    | `pmatrix`     |
| $\begin{bmatrix}a&b\\c&d\end{bmatrix}$                                    | `bmatrix`     |
| $\begin{vmatrix}a&b\\c&d\end{vmatrix}$                                    | `vmatrix`     |
| $\begin{Vmatrix}a&b\\c&d\end{Vmatrix}$                                    | `Vmatrix`     |
| $\begin{Bmatrix}a&b\\c&d\end{Bmatrix}$                                    | `Bmatrix`     |
| $x=\begin{cases}a&\text{if }b\\c&\text{if }d\end{cases}$                  | `cases`       |
| $\begin{smallmatrix}a&b\\c&d\end{smallmatrix}$                            | `smallmatrix` |
| $\displaystyle\sum_{\begin{subarray}{l}i\in\Lambda\\0<j<n\end{subarray}}$ | `subarray`    |
| $\begin{aligned} a&=b+c\\ d+e&=f \end{aligned}$                           | `aligned`     |
| $\begin{gathered} a=b\\ e=b+c \end{gathered}$                             | `gathered`    |
| $\begin{alignedat}{2} 10&x+&3&y=2\\ 3&x+&13&y=4 \end{alignedat}$          | `alignedat`   |

## Letters and Unicode

### Greek Letters

| Content       | Syntax        | Content       | Syntax        |
| ------------- | ------------- | ------------- | ------------- |
| $\Alpha$      | `\Alpha`      | $\alpha$      | `\alpha`      |
| $\Beta$       | `\Beta`       | $\beta$       | `\beta`       |
| $\Gamma$      | `\Gamma`      | $\gamma$      | `\gamma`      |
| $\Epsilon$    | `\Epsilon`    | $\epsilon$    | `\epsilon`    |
| $\Zeta$       | `\Zeta`       | $\zeta$       | `\zeta`       |
| $\Eta$        | `\Eta`        | $\eta$        | `\eta`        |
| $\Theta$      | `\Theta`      | $\theta$      | `\theta`      |
| $\Iota$       | `\Iota`       | $\iota$       | `\iota`       |
| $\Kappa$      | `\Kappa`      | $\kappa$      | `\kappa`      |
| $\Lambda$     | `\Lambda`     | $\lambda$     | `\lambda`     |
| $\Mu$         | `\Mu`         | $\mu$         | `\mu`         |
| $\Nu$         | `\Nu`         | $\nu$         | `\nu`         |
| $\Xi$         | `\Xi`         | $\xi$         | `\xi`         |
| $\Omicron$    | `\Omicron`    | $\omicron$    | `\omicron`    |
| $\Pi$         | `\Pi`         | $\pi$         | `\pi`         |
| $\Rho$        | `\Rho`        | $\rho$        | `\rho`        |
| $\Sigma$      | `\Sigma`      | $\sigma$      | `\sigma`      |
| $\Tau$        | `\Tau`        | $\tau$        | `\tau`        |
| $\Upsilon$    | `\Upsilon`    | $\upsilon$    | `\upsilon`    |
| $\Phi$        | `\Phi`        | $\phi$        | `\phi`        |
| $\Chi$        | `\Chi`        | $\chi$        | `\chi`        |
| $\Psi$        | `\Psi`        | $\psi$        | `\psi`        |
| $\Omega$      | `\Omega`      | $\omega$      | `\omega`      |
| $\varGamma$   | `\varGamma`   | $\varepsilon$ | `\varepsilon` |
| $\varTheta$   | `\varTheta`   | $\varkappa$   | `\varkappa`   |
| $\varLambda$  | `\varLambda`  | $\vartheta$   | `\vartheta`   |
| $\varXi$      | `\varXi`      | $\thetasym$   | `\thetasym`   |
| $\varPi$      | `\varPi`      | $\varpi$      | `\varpi`      |
| $\varSigma$   | `\varSigma`   | $\varrho$     | `\varrho`     |
| $\varUpsilon$ | `\varUpsilon` | $\varsigma$   | `\varsigma`   |
| $\varPhi$     | `\varPhi`     | $\varphi$     | `\varphi`     |
| $\varPsi$     | `\varPsi`     | $\digamma$    | `\digamma`    |
| $\varOmega$   | `\varOmega`   |

### Other Letters

| Content      | Syntax       | Content      | Syntax       |
| ------------ | ------------ | ------------ | ------------ |
| $\imath$     | `\imath`     | $\jmath$     | `\jmath`     |
| $\aleph$     | `\aleph`     | $\alef$      | `\alef`      |
| $\alefsym$   | `\alefsym`   | $\beth$      | `\beth`      |
| $\gimel$     | `\gimel`     | $\daleth$    | `\daleth`    |
| $\eth$       | `\eth`       | $\nabla$     | `\nabla`     |
| $\partial$   | `\partial`   | $\Game$      | `\Game`      |
| $\Finv$      | `\Finv`      | $\cnums$     | `\cnums`     |
| $\Complex$   | `\Complex`   | $\ell$       | `\ell`       |
| $\hbar$      | `\hbar`      | $\hslash$    | `\hslash`    |
| $\Im$        | `\Im`        | $\image$     | `\image`     |
| $\Bbbk$      | `\Bbbk`      | $\N$         | `\N`         |
| $\natnums$   | `\natnums`   | $\R$         | `\R`         |
| $\Re$        | `\Re`        | $\real$      | `\real`      |
| $\reals$     | `\reals`     | $\Reals$     | `\Reals`     |
| $\wp$        | `\wp`        | $\weierp$    | `\weierp`    |
| $\Z$         | `\Z`         | $\text{\aa}$ | `\text{\aa}` |
| $\text{\AA}$ | `\text{\AA}` | $\text{\ae}$ | `\text{\ae}` |
| $\text{\AE}$ | `\text{\AE}` | $\text{\oe}$ | `\text{\oe}` |
| $\text{\OE}$ | `\text{\OE}` | $\text{\o}$  | `\text{\o}`  |
| $\text{\O}$  | `\text{\O}`  | $\text{\ss}$ | `\text{\ss}` |
| $\text{\i}$  | `\text{\i}`  | $\text{\j}$  | `\text{\j}`  |

## Layout

| Content                          | Syntax                           |
| -------------------------------- | -------------------------------- |
| $\cancel{5}$                     | `\cancel{5}`                     |
| $\bcancel{5}$                    | `\bcancel{5}`                    |
| $\xcancel{ABC}$                  | `\xcancel{ABC}`                  |
| $\sout{abc}$                     | `\sout{abc}`                     |
| $\overbrace{a+b+c}^\text{note}$  | `\overbrace{a+b+c}^\text{note}`  |
| $\underbrace{a+b+c}_\text{note}$ | `\underbrace{a+b+c}_\text{note}` |
| $\not =$                         | `\not =`                         |
| $\boxed{\pi=\frac c d}$          | `\boxed{\pi=\frac c d}`          |

$$
\tag{hi} x+y^{2x}
$$

```t
\tag{hi} x+y^{2x}
```

$$
\tag*{hi} x+y^{2x}
$$

```t
\tag*{hi} x+y^{2x}
```

### Vertical Layout

| Content                          | Syntax                           |
| -------------------------------- | -------------------------------- |
| $x_n$                            | `x_n`                            |
| $e^x$                            | `e^x`                            |
| $_u^o$                           | `_u^o`                           |
| $\stackrel{!}{=}$                | `\stackrel{!}{=}`                |
| $\overset{!}{=}$                 | `\overset{!}{=}`                 |
| $\underset{!}{=}$                | `\underset{!}{=}`                |
| $a \atop b$                      | `a \atop b`                      |
| $a\raisebox{0.25em}{b}c$         | `a\raisebox{0.25em}{b}c`         |
| $\sum_{\substack{0<i<m\\0<j<n}}$ | `\sum_{\substack{0<i<m\\0<j<n}}` |

### Overlap and Spacing

| Content                                                  | Syntax                                      |
| -------------------------------------------------------- | ------------------------------------------- |
| ${=}\mathllap{/\,}$                                      | `{=}\mathllap{/\,}`                         |
| $\mathrlap{\,/}{=}$                                      | `\mathrlap{\,/}{=}`                         |
| $\left(x^{\smash{2}}\right)$                             | `\left(x^{\smash{2}}\right)`                |
| $\sqrt{\smash[b]{y}}$                                    | `\sqrt{\smash[b]{y}}`                       |
| $\displaystyle\sum_{\mathclap{1\le i\le j\le n}} x_{ij}$ | `\sum_{\mathclap{1\le i\le j\le n}} x_{ij}` |

#### Spacing

| Function             | Produces                              |
| -------------------- | ------------------------------------- |
| `\,`                 | ³∕₁₈ em space                         |
| `\thinspace`         | ³∕₁₈ em space                         |
| `\>`                 | ⁴∕₁₈ em space                         |
| `\:`                 | ⁴∕₁₈ em space                         |
| `\medspace`          | ⁴∕₁₈ em space                         |
| `\;`                 | ⁵∕₁₈ em space                         |
| `\thickspace`        | ⁵∕₁₈ em space                         |
| `\enspace`           | ½ em space                            |
| `\quad`              | 1 em space                            |
| `\qquad`             | 2 em space                            |
| `~`                  | non-breaking space                    |
| `\<space>`           | space                                 |
| `\nobreakspace`      | non-breaking space                    |
| `\space`             | space                                 |
| `\kern{distance}`    | space, width = distance               |
| `\mkern{distance}`   | space, width = distance               |
| `\mskip{distance}`   | space, width = distance               |
| `\hskip{distance}`   | space, width = distance               |
| `\hspace{distance}`  | space, width = distance               |
| `\hspace*{distance}` | space, width = distance               |
| `\phantom{content}`  | space the width and height of content |
| `\hphantom{content}` | space the width of content            |
| `\vphantom{content}` | a strut the height of content         |
| `\!`                 | –³∕₁₈ em space                        |
| `\negthinspace`      | –³∕₁₈ em space                        |
| `\negmedspace`       | -⁴∕₁₈ em space                        |
| `\negthickspace`     | -⁵∕₁₈ em space                        |
| `\mathstrut`         | `\vphantom{(}`                        |

**Notes:**

`distance` will accept any of the [KaTeX units](#units).

`\kern`, `\mkern`, `\mskip`, and `\hspace` accept unbraced distances, as in: `\kern1m`.

## Logic and Set Theory

| Content       | Syntax        | Content           | Syntax            |
| ------------- | ------------- | ----------------- | ----------------- |
| $\forall$     | `\forall`     | $\therefore$      | `\therefore`      |
| $\exists$     | `\exists`     | $\because$        | `\because`        |
| $\exist$      | `\exist`      | $\mapsto$         | `\mapsto`         |
| $\nexists$    | `\nexists`    | $\to$             | `\to`             |
| $\in$         | `\in`         | $\gets$           | `\gets`           |
| $\isin$       | `\isin`       | $\leftrightarrow$ | `\leftrightarrow` |
| $\notin$      | `\notin`      | $\notni$          | `\notni`          |
| $\complement$ | `\complement` | $\emptyset$       | `\emptyset`       |
| $\subset$     | `\subset`     | $\empty$          | `\empty`          |
| $\supset$     | `\supset`     | $\varnothing$     | `\varnothing`     |
| $\mid$        | `\mid`        | $\implies$        | `\implies`        |
| $\land$       | `\land`       | $\impliedby$      | `\impliedby`      |
| $\lor$        | `\lor`        | $\iff$            | `\iff`            |
| $\ni$         | `\ni`         | $\neg$            | `\neg`            |
| $\lnot$       | `\lnot`       |

## Operators

### Big Operators

| Content     | Syntax      | Content      | Syntax       |
| ----------- | ----------- | ------------ | ------------ |
| $\sum$      | `\sum`      | $\bigotimes$ | `\bigotimes` |
| $\int$      | `\int`      | $\bigoplus$  | `\bigoplus`  |
| $\iint$     | `\iint`     | $\bigodot$   | `\bigodot`   |
| $\iiint$    | `\iiint`    | $\biguplus$  | `\biguplus`  |
| $\oint$     | `\oint`     | $\oiiint$    | `\oiiint`    |
| $\prod$     | `\prod`     | $\bigvee$    | `\bigvee`    |
| $\coprod$   | `\coprod`   | $\bigwedge$  | `\bigwedge`  |
| $\intop$    | `\intop`    | $\bigcap$    | `\bigcap`    |
| $\smallint$ | `\smallint` | $\bigcup$    | `\bigcup`    |
| $\oiint$    | `\oiint`    | $\bigsqcup$  | `\bigsqcup`  |

### Binary Operators

| Content           | Syntax            | Content            | Syntax             |
| ----------------- | ----------------- | ------------------ | ------------------ |
| $+$               | `+`               | $\gtrdot$          | `\gtrdot`          |
| $-$               | `-`               | $\intercal$        | `\intercal`        |
| $*$               | `*`               | $\land$            | `\land`            |
| $/$               | `/`               | $\leftthreetimes$  | `\leftthreetimes`  |
| $\amalg$          | `\amalg`          | $\ldotp$           | `\ldotp`           |
| $\And$            | `\And`            | $\lor$             | `\lor`             |
| $\ast$            | `\ast`            | $\lessdot$         | `\lessdot`         |
| $\barwedge$       | `\barwedge`       | $\lhd$             | `\lhd`             |
| $\bigcirc$        | `\bigcirc`        | $\ltimes$          | `\ltimes`          |
| $\bmod$           | `\bmod`           | $x\mod a$          | `x\mod a`          |
| $\boxdot$         | `\boxdot`         | $\mp$              | `\mp`              |
| $\boxminus$       | `\boxminus`       | $\odot$            | `\odot`            |
| $\boxplus$        | `\boxplus`        | $\ominus$          | `\ominus`          |
| $\boxtimes$       | `\boxtimes`       | $\oplus$           | `\oplus`           |
| $\bullet$         | `\bullet`         | $\otimes$          | `\otimes`          |
| $\Cap$            | `\Cap`            | $\oslash$          | `\oslash`          |
| $\cap$            | `\cap`            | $\pm$              | `\pm`              |
| $\cdot$           | `\cdot`           | $\plusmn$          | `\plusmn`          |
| $\cdotp$          | `\cdotp`          | $x\pmod a$         | `x\pmod a`         |
| $\centerdot$      | `\centerdot`      | $x\pod a$          | `x\pod a`          |
| $\circ$           | `\circ`           | $\rhd$             | `\rhd`             |
| $\circledast$     | `\circledast`     | $\rightthreetimes$ | `\rightthreetimes` |
| $\circledcirc$    | `\circledcirc`    | $\rtimes$          | `\rtimes`          |
| $\circleddash$    | `\circleddash`    | $\setminus$        | `\setminus`        |
| $\Cup$            | `\Cup`            | $\smallsetminus$   | `\smallsetminus`   |
| $\cup$            | `\cup`            | $\sqcap$           | `\sqcap`           |
| $\curlyvee$       | `\curlyvee`       | $\sqcup$           | `\sqcup`           |
| $\curlywedge$     | `\curlywedge`     | $\times$           | `\times`           |
| $\div$            | `\div`            | $\unlhd$           | `\unlhd`           |
| $\divideontimes$  | `\divideontimes`  | $\unrhd$           | `\unrhd`           |
| $\dotplus$        | `\dotplus`        | $\uplus$           | `\uplus`           |
| $\doublebarwedge$ | `\doublebarwedge` | $\vee$             | `\vee`             |
| $\doublecap$      | `\doublecap`      | $\veebar$          | `\veebar`          |
| $\doublecup$      | `\doublecup`      | $\wedge$           | `\wedge`           |
| $\wr$             | `\wr`             |

### Fractions and Binomials

| Content                       | Syntax                        |
| ----------------------------- | ----------------------------- |
| $\frac{a}{b}$                 | `\frac{a}{b}`                 |
| $a\over b$                    | `a\over b`                    |
| $a/b$                         | `a/b`                         |
| $\tfrac{a}{b}$                | `\tfrac{a}{b}`                |
| $\dfrac{a}{b}$                | `\dfrac{a}{b}`                |
| $\genfrac ( ] {2pt}{1}a{a+1}$ | `\genfrac ( ] {2pt}{1}a{a+1}` |
| $a\above{2pt} b+1$            | `a\above{2pt} b+1`            |
| $\cfrac{a}{1 + \cfrac{1}{b}}$ | `\cfrac{a}{1 + \cfrac{1}{b}}` |
| $\binom{n}{k}$                | `\binom{n}{k}`                |
| $n\choose k$                  | `n\choose k`                  |
| $\dbinom{n}{k}$               | `\dbinom{n}{k}`               |
| $\tbinom{n}{k}$               | `\tbinom{n}{k}`               |
| $n\brace k$                   | `n\brace k`                   |
| $n\brack k$                   | `n\brack k`                   |

### Math Operators

| Content   | Syntax    | Content             | Syntax              |
| --------- | --------- | ------------------- | ------------------- |
| $\arcsin$ | `\arcsin` | $\sec$              | `\sec`              |
| $\arccos$ | `\arccos` | $\sin$              | `\sin`              |
| $\arctan$ | `\arctan` | $\sinh$             | `\sinh`             |
| $\arctg$  | `\arctg`  | $\sh$               | `\sh`               |
| $\arcctg$ | `\arcctg` | $\tan$              | `\tan`              |
| $\arg$    | `\arg`    | $\tanh$             | `\tanh`             |
| $\ch$     | `\ch`     | $\tg$               | `\tg`               |
| $\cos$    | `\cos`    | $\th$               | `\th`               |
| $\cosec$  | `\cosec`  | $\operatorname{f}$  | `\operatorname{f}`  |
| $\cosh$   | `\cosh`   | $\argmax$           | `\argmax`           |
| $\cot$    | `\cot`    | $\argmin$           | `\argmin`           |
| $\cotg$   | `\cotg`   | $\det$              | `\det`              |
| $\coth$   | `\coth`   | $\gcd$              | `\gcd`              |
| $\csc$    | `\csc`    | $\inf$              | `\inf`              |
| $\ctg$    | `\ctg`    | $\lim$              | `\lim`              |
| $\cth$    | `\cth`    | $\liminf$           | `\liminf`           |
| $\deg$    | `\deg`    | $\limsup$           | `\limsup`           |
| $\dim$    | `\dim`    | $\max$              | `\max`              |
| $\exp$    | `\exp`    | $\min$              | `\min`              |
| $\hom$    | `\hom`    | $\plim$             | `\plim`             |
| $\ker$    | `\ker`    | $\Pr$               | `\Pr`               |
| $\lg$     | `\lg`     | $\sup$              | `\sup`              |
| $\ln$     | `\ln`     | $\operatorname*{f}$ | `\operatorname*{f}` |
| $\log$    | `\log`    |

Functions below `\operatorname` can take `\limits`.

### \sqrt

| Content       | Syntax        |
| ------------- | ------------- |
| $\sqrt{x}$    | `\sqrt{x}`    |
| $\sqrt[3]{x}$ | `\sqrt[3]{x}` |

## Relations :building_construction:

## Special Notation :building_construction:

## Symbols and Punctuation :building_construction:

## Units :building_construction:

# Appendix

- [GitHub Flavored Markdown Spec](https://github.github.com/gfm/)
- [KaTeX Supported Functions](https://katex.org/docs/supported.html)
- [Flutter Math Demo](https://znjameswu.github.io/flutter_math_demo/#/)

