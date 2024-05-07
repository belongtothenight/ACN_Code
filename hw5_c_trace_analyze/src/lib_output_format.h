/**
 * @file  lib_output_format.h
 * @brief Output format struct for color printing (charactors)
 * @author belongtothenight / Da-Chuan Chen / 2024
 * Ref:
 * 1. https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
 * 2. https://stackoverflow.com/questions/37774983/clearing-the-screen-by-printing-a-character
 * 3. https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
*/

#ifndef OUTPUT_FORMAT_H
#define OUTPUT_FORMAT_H

//! @cond Doxygen_Suppress
/**
 * @brief Output format struct for color printing (charactors)
 * @details This struct contains all the color codes for printing in terminal
 */
typedef struct{
    /// @brief Styles
    struct Styles{
        const char *reset;        ///< reset
        const char *bold;         ///< bold
        const char *underline;    ///< underline
        const char *inverse;      ///< inverse
    } style;
    /// @brief Text colors
    struct Foreground{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } foreground;
    /// @brief Background colors
    struct Background{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } background;
    /// @brief Strong text colors
    struct Strong_Foreground{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } strong_foreground;
    /// @brief Strong background colors
    struct Strong_Background{
        const char *black;        ///< black
        const char *red;          ///< red
        const char *green;        ///< green
        const char *yellow;       ///< yellow
        const char *blue;         ///< blue
        const char *magenta;      ///< magenta
        const char *cyan;         ///< cyan
        const char *white;        ///< white
    } strong_background;
    /// @brief Status
    struct Status{
        const char *success;      ///< success
        const char *warning;      ///< warning
        const char *error;        ///< error
        const char *pass;         ///< pass
        const char *fail;         ///< fail
    } status;
} output_format;
//! @endcond

/**
 * @brief Get the format object, return the format struct with value assigned
 * @param pFormat pointer to the output_format struct
 * @return void
*/
void get_format (output_format* pFormat);

#endif
